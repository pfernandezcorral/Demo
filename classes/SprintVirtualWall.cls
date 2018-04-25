/*
*   SprintWall Controller
*   Created by: jgaviria@copa.do
*   Test Class: TestSprintVirtualWall
*   Last Modification:
*/

public with sharing class SprintVirtualWall {

    public Id nextSprintId {get; set;}
    public Id previousSprintId {get; set;}
    public SprintWrapper sw {get; set;}
    public User_Story__c massUpdateUS {get; set;}
    public Integer plannedVelocity {get; set;}
    public Integer actualVelocity {get; set;}
    public String daysLeft {get; set;}
    public String sprintEdit {get; set;}
    public String lastSelectedRT {get; set;}
    public String actionIndex {get; set;}
    public List<SelectOption> usRecordTypes {get; set;}
    public Map<String, String> rtWithId {get; set;}
    private Map<String, String> rtIdWithName {get; set;}
    //Variable to Store Error Messages to show as lightning
    public String errorMessage {get; set;}
    //Variable to Store Error Messages to show as lightning
    public String errorDetails {get; set;}
    //Action Function Parameter to assign user selected record type
    public String usRtId {get; set;}
    public boolean isLightning {get;set;}
    //Customizable Statuses to calculate actual velocities
    public Set<String> actualVelStatus {get;set;}
    //Map that will contain Filters and Values
    public Map<String,List<String>> filterWithValues {get;set;} 
    //Map to store filters for User
    public Map<String,Boolean> filterNameWithFlag {get;set;} 
    private Map<String,String> uIdWithName;
    /*
        Method to check if user is using lightning experience
        Used to add retURL parameters if in classic

     */
    /*Pagination variables*/
    private integer offSetCounter = 0; //keeps track of the offset
    private integer listSize = 200; //sets the page size or number of rows
    public integer totalListSize; //used to show user the total size of the list    
    public boolean isLight() {
        String iframeURL = ApexPages.currentPage().getParameters().get('sfdcIFrameOrigin');
        if (String.isNotBlank(iframeURL) && iframeURL.contains('.lightning.')) {
            return true;
        } else {
            return false;
        }

    }
    /*
        Standard Controller onstructor
     */
    public SprintVirtualWall(ApexPages.StandardController stdController) {
    if (!Test.isRunningTest()) stdController.addFields(new List<String>(Schema.SObjectType.Sprint__c.fields.getMap().keySet()));
    filterNameWithFlag = new Map<String,Boolean> ();
        //New ability to customize the calculation of actual velocity based on custom metadata
        actualVelStatus = new Set<String>();
        Copado_Setting__mdt cs = [SELECT Id, Text_Field__c FROM Copado_Setting__mdt WHERE DeveloperName = 'Actual_Velocity_Statuses' LIMIT 1];
        if(String.isNotBlank(cs.Text_Field__c)){
            List<String> allStatus = cs.Text_Field__c.split(',');
            List<String> allStatusTrim = new List<String>();
            for(String s : allStatus){
                s = s.trim();
                allStatusTrim.add(s);
            }
            actualVelStatus.addAll(allStatusTrim);
        }else{
            actualVelStatus.add('Completed');
        }

        isLightning = isLight();
        //Give Memory to massUpdateUS
        massUpdateUS = new User_Story__c(Status__c = '');
        refreshSprint((Id)stdController.getId());
        sprintEdit = String.valueOf(new Apexpages.StandardController(sw.theSprint).edit());
        //Fill usRecordTypes
        queryusRecordTypes();
    }
    /*
        Fill all properties used for new record types logic and changing record types on
        inline edit
     */
    private void queryusRecordTypes() {
        usRecordTypes = new List<SelectOption>();
        rtWithId = new Map<String, String>();
        rtIdWithName = new Map<String, String>();
        usRecordTypes.add(new SelectOption('', '--none--'));
        String userStoryType = Settings.ns + 'User_Story__c';
        for (RecordType rt : [select Id, Name, DeveloperName from RecordType where SobjectType =: userStoryType]) {
            usRecordTypes.add(new SelectOption(rt.Name, rt.Name));
            rtWithId.put(rt.Name, rt.Id);
            rtIdWithName.put(rt.id, rt.Name);
        }
    }
    public PageReference Beginning() { //pagination beginning
        offSetCounter = 0;
        refreshSprint(sw.sId);
        return null;
    }

    public PageReference Previous() { //pagination previous button
        offSetCounter -= listSize;
        refreshSprint(sw.sId);
        return null;
    }

    public PageReference Next() { //pagination next button
        offSetCounter += listSize;
        refreshSprint(sw.sId);
        return null;
    }
    public PageReference End() { //pagination end
        offSetCounter = totalListSize - math.mod(totalListSize, listSize);
        refreshSprint(sw.sId);
        return null;
    }
    public Boolean getDisablePrevious() {
        //this will disable the previous and beginning buttons
        if (offSetCounter > 0) {
            return false; 
        } else {
            return true;
        }
    }
    public Boolean getDisableNext() {
        //this will disable the next and end buttons
        if (offSetCounter + listSize < totalListSize){ 
            return false;
        } else {
            return true;
        }
    }
    public Integer getTotalListSize() {
        return totalListSize;
    }
    public Integer getCounter() {
        return offSetCounter;
    }
    public Integer getListSize(){
        return listSize;
    }

    public Integer getPageNumber() {
        return offSetCounter / listSize + 1;
    }
    public Integer getTotalPages() {
        if (math.mod(totalListSize, listSize) > 0) {
            return totalListSize / listSize + 1;
        } else {
            return (totalListSize / listSize);
        }
    }
    private List<User_Story__c> getUserStories(Id sId) {
        try {
            String qCols = '';
            for (Schema.FieldSetMember fs : SObjectType.User_Story__c.FieldSets.Sprint_Wall_Columns.getFields()) {
                qCols += fs.getFieldPath() +' , ';
            }
            String q = 'SELECT Id, Name, Status__c, RecordTypeId, Recordtype.Name, Developer__c, Developer__r.Name, '+
                                          'Owner.Name, OwnerId, User_Story_Title__c, Business_Analyst__c, '+
                                          'Test_Script_Owner__c, Order__c, Story_Points_SFDC__c, ' +
                                          qCols+
                                          '(select Id, Subject__c, Hours_Remaining__c, Status__c, User_Story__c '+                                      
                                          'from User_Story_Tasks__r '+
                                          'Order by Hours_Remaining__c) '+
                                          'FROM User_Story__c '+
                                          'WHERE Sprint__c = : sId '+
                                          'ORDER BY Order__c ASC, CreatedDate NULLS LAST ' +
                                          'LIMIT :listSize ' +
                                          'OFFSET :offSetCounter ';
            system.debug(q);
            return Database.Query(q);
        } catch (Exception ex) {
            catchException(ex);
            return null;
        }
    }


    /*
        SOQLs and wrapper initialiaztion/sets
     */
    private void refreshSprint(Id sId) {
        //Select to know how may records there are
        totalListSize = [SELECT count() FROM User_Story__c WHERE Sprint__c = : sId];
        //Query the actual Sprint
        Sprint__c sprint = [SELECT Id, Name, Start_Date__c, End_Date__c, Project__c, Status__c
                            FROM Sprint__c
                            WHERE Id = : sId];

        List<Sprint__c> nextSprintList = [SELECT Id
                                          FROM Sprint__c
                                          WHERE Start_Date__c >= : sprint.End_Date__c
                                          AND Id != : sId
                                          Order by Start_Date__c limit 1];
        if (nextSprintList.size() > 0) {
            nextSprintId = nextSprintList[0].Id;
        }
        List<Sprint__c> prevSprintList = [SELECT Id
                                          FROM Sprint__c
                                          WHERE End_Date__c <= : sprint.Start_Date__c
                                          AND Id != : sId
                                          Order by End_Date__c Desc limit 1];
        if (prevSprintList.size() > 0) {
            previousSprintId = prevSprintList[0].Id;
        }
        //Give Memory and Assign the sprint to the wrapper
        sw = new SprintWrapper();
        sw.sId = sId;
        sw.theSprint = sprint;
        //calculate the remaining Days
        daysLeft = calculateDaysLeftString(sprint);
        //Now this is limited and pagination will be included
        List<User_Story__c> usList = getUserStories(sId);
        //If the Sprint has User Stories related then we give
        if (usList.size() > 0) {
            //iterate List to see if order exist or if same order exists, else assign new order
            Boolean recalcOrder = false;
            for (integer i = 0; i < usList.size(); i++) {
                decimal usOrder = usList[i].Order__c;
                if (usOrder == null) {
                    recalcOrder = true;
                    break;
                }
                //comparing if same order exist
                for (integer j = 0; j < usList.size(); j++) {
                    decimal usBOrder = usList[j].Order__c;
                    if ((usOrder != null && usBOrder != null) && (usOrder != usBOrder)) {
                        recalcOrder = true;
                        break;
                    }
                }
                // check if next one is not current index+1
                if (i + 1 < usList.size() && usList[i + 1].Order__c != null && usOrder + 1 != usList[i + 1].Order__c) {
                    recalcOrder = true;
                    break;
                }
            }
            //iterate over all User Stories and fill the wrappers
            sw.userStories = new List<UserStoryWrapper>();
            integer index = 0;
            //fill onload Map
            uIdWithName = new Map<String,String>();            
            for (User_Story__c us : usList) {      
                if(!uIdWithName.containsKey(us.Developer__c)){
                    uIdWithName.put(us.Developer__c,us.Developer__r.Name);
                }          
                UserStoryWrapper usw = new UserStoryWrapper();
                usw.theUs = us;
                usw.rt = us.RecordType.Name;
                if (recalcOrder) {
                    usw.theUs.Order__c = index+offSetCounter;
                }
                usw.selected = false;
                usw.index = index;
                usw.removed = false;

                sw.userStories.add(usw);
                index++;
                usw.theTasks = new Map<String, List<USTaskWrapper>>();
                usw.theTasks.put('Not Started', new List<USTaskWrapper>());
                usw.theTasks.put('In Progress', new List<USTaskWrapper>());
                usw.theTasks.put('Completed', new List<USTaskWrapper>());
                if (us.User_Story_Tasks__r.size() > 0) {
                    for (User_Story_Task__c ust : us.User_Story_Tasks__r) {
                        USTaskWrapper uw = new USTaskWrapper();
                        uw.theUSTask = ust;
                        if (ust.Status__c != 'In Progress' && ust.Status__c != 'Completed') {
                            List<USTaskWrapper> l = usw.theTasks.get('Not Started');
                            l.add(uw);
                        } else {
                            List<USTaskWrapper> l = usw.theTasks.get(ust.Status__c);
                            l.add(uw);
                        }
                    }
                }
            }
            calculateVelocities();
            calculateFilters();
        }
    }
    /*
        Method to set actual and planned velocity based on what the wrapper has.
        The difference between planned and actual is that actual are for the Completed USs
     */
     public PageReference calculateFilters(){
        //Give memory to the filters, add new if ever needed
        filterWithValues = new Map<String,List<String>>();
        filterWithValues.put('Record Type', new List<String>());
        filterWithValues.put('Status', new List<String>());
        filterWithValues.put('Assignee', new List<String>());    
        //three sets are needed to add non repeated values and to assign them to the List so they are iterable on VF
        Set<String> rtAvailable = new Set<String>();
        Set<String> statusAvailable = new Set<String>();
        Set<String> assigneeAvailable = new Set<String>();
        //a set is needed for Ids of Assignees that were not queried on load
        Set<String> userIds = new Set<String>();
        for (UserStoryWrapper usw : sw.userStories){
            if(!usw.removed){
                if(usw.theUs.Recordtype.Name != null){
                    rtAvailable.add(usw.theUs.Recordtype.Name);
                    if(!filterNameWithFlag.containsKey(usw.theUs.Recordtype.Name)){
                        filterNameWithFlag.put(usw.theUs.Recordtype.Name, false);
                    }
                    
                }
                if(String.isNotBlank(usw.theUs.Status__c)){
                    statusAvailable.add(usw.theUs.Status__c);
                    if(!filterNameWithFlag.containsKey(usw.theUs.Status__c)){
                        filterNameWithFlag.put(usw.theUs.Status__c, false);
                    }
                }
                if(uIdWithName.containsKey(usw.theUs.Developer__c)){
                    assigneeAvailable.add(uIdWithName.get(usw.theUs.Developer__c));
                    if(!filterNameWithFlag.containsKey(usw.theUs.Developer__r.Name)){
                        filterNameWithFlag.put(usw.theUs.Developer__r.Name, false);
                    }
                }else if(usw.theUs.Developer__c != null){
                    //Name has to be queried, so add to Set
                    userIds.add(usw.theUs.Developer__c);
                }
            }
        }
        if(userIds.size()>0){
            for(User u : [SELECT Id, Name FROM User WHERE Id IN : userIds]){
                assigneeAvailable.add(u.Name);
                uIdWithName.put(u.Id, u.Name);
                if(!filterNameWithFlag.containsKey(u.Name)){
                    filterNameWithFlag.put(u.Name, false);
                }
            }
        }

        //assign the sets to the List inside the Map
        filterWithValues.get('Record Type').addAll(rtAvailable);
        filterWithValues.get('Status').addAll(statusAvailable);
        filterWithValues.get('Assignee').addAll(assigneeAvailable);
        return null;
     }



    /*
        Method to set actual and planned velocity based on what the wrapper has.
        The difference between planned and actual is that actual are for the Completed USs
     */
    public PageReference calculateVelocities() {
        system.debug('Entering Calculate Velocities');
        if (sw.userStories != null && sw.userStories.size() > 0) {
            integer actualV = 0;
            integer plannedV = 0;
            for (UserStoryWrapper usw : sw.userStories) {
                if (usw.theUs.Story_Points_SFDC__c != null && usw.theUs.Story_Points_SFDC__c > 0 && !usw.removed && actualVelStatus.contains(usw.theUs.Status__c)) {
                    actualV = actualV + Integer.valueOf(usw.theUs.Story_Points_SFDC__c);
                }
                if (usw.theUs.Story_Points_SFDC__c != null && usw.theUs.Story_Points_SFDC__c > 0 && !usw.removed) {
                    plannedV = plannedV + Integer.valueOf(usw.theUs.Story_Points_SFDC__c);
                }
            }
            //actualVelocity = actualV;
            //plannedVelocity = plannedV;
            AggregateResult[] actual = [SELECT sum(Story_Points_SFDC__c) sum FROM User_Story__c WHERE Sprint__c =: sw.sId AND Status__c IN : actualVelStatus];
            actualVelocity = Integer.valueOf(actual[0].get('sum'));
            AggregateResult[] planned = [SELECT sum(Story_Points_SFDC__c) sum FROM User_Story__c WHERE Sprint__c =: sw.sId];
            plannedVelocity = Integer.valueOf(planned[0].get('sum'));
        }
        return null;
    }
    /*
        Method to calculate days left depending on today's date
     */
    private String calculateDaysLeftString(Sprint__c s) {
        String dString = '';
        if (date.today() > s.End_Date__c) {
            dString = system.label.SprintWall_DaysLeft_Closed;
        } else if (date.today() < s.Start_Date__c) {
            dString = system.label.SprintWall_DaysLeft_Not_Started;
        } else if (s.End_Date__c != null) {
            dString = String.valueOf(date.today().daysBetween(s.End_Date__c));
        }
        return dString;
    }

    /*
        If there is a next sprint available this will be available and will
        execute a update of the parent Sprint to the US
     */
    public PageReference moveToNextSprint() {
        try {
            errorMessage = '';
            Integer ind = Integer.valueOf(ApexPages.currentPage().getParameters().get('mtnsIndex'));
            sw.userStories[Integer.valueOf(ind)].theUS.Sprint__c = nextSprintId;
            sw.userStories[Integer.valueOf(ind)].theUS.Order__c = null;
            Utilities.Secure_DML(sw.userStories[Integer.valueOf(ind)].theUS, Utilities.DML_Action.UPS, schema.Sobjecttype.User_Story__c);
            if(!ApexPages.hasMessages()){
                sw.userStories[Integer.valueOf(ind)].removed = true;
            }else{
                errorMessage = errorMessage + String.valueOf(ApexPages.getMessages());
                system.debug(logginglevel.ERROR, errorMessage);
            }
            Integer index = 0;
            for (UserStoryWrapper usw : sw.userStories) {
                usw.index = index;
                index++;
            }
            calculateVelocities();
        } catch (exception e) {
            catchException(e);
        }
        return null;

    }
    /*
        Removes parent sprint and order from current US
     */
    public PageReference removeFromCurrenSprint() {
        try {            
            errorMessage = '';
            Integer ind = Integer.valueOf(ApexPages.currentPage().getParameters().get('removeRowIndex'));
            system.debug(ind);
            sw.userStories[ind].theUS.Sprint__c = null;
            sw.userStories[ind].theUS.Order__c = null;
            Utilities.Secure_DML(sw.userStories[ind].theUS, Utilities.DML_Action.UPS, schema.Sobjecttype.User_Story__c);
            sw.userStories[Integer.valueOf(ind)].removed = true;
            Integer index = 0;
            for (UserStoryWrapper usw : sw.userStories) {
                usw.index = index;
                index++;
            }
            calculateVelocities();
        } catch (exception e) {
            catchException(e);
        }
        return null;
    }
    /*
        Method on mass update button iterates over all fileds on field set and
        they have value it is set to every US that is checked
     */
    public PageReference massUpdateRecords() {
        try {
            errorMessage = '';
            List<User_Story__c> usToUpdate = new List<User_Story__c>();
            for (UserStoryWrapper usw : sw.userStories) {
                if (usw.selected) {
                    for (Schema.FieldSetMember fs : SObjectType.User_Story__c.FieldSets.SprintWall_MassUpdate.getFields()) {
                        if (massUpdateUS.get(fs.getFieldPath()) != null) {
                            usw.theUS.put(fs.getFieldPath(), massUpdateUS.get(fs.getFieldPath()));
                            if(fs.getFieldPath().contains('Sprint__c')){
                                usw.removed = true;
                                usw.theUS.Order__c = 0;
                            }
                        }
                    }
                    usToUpdate.add(usw.theUS);
                }
            }
            if (usToUpdate.size() > 0) {
                Utilities.Secure_DML(usToUpdate, Utilities.DML_Action.UPS, schema.Sobjecttype.User_Story__c);
                massUpdateUS = new User_Story__c();
                calculateFilters();
                calculateVelocities();
            }
        } catch (exception e) {
            catchException(e);
        }
        return null;
    }
    /*
        Method for New User Story button, record type is selected on the view
        using the radiobuttons and is set here
     */
    public PageReference newUserStory() {
        PageReference pr;
        try {
            errorMessage = '';
            system.debug(logginglevel.ERROR, usRtId);
            UserStoryWrapper usw = new UserStoryWrapper();
            User_Story__c us = new User_Story__c();
            us.Sprint__c = sw.sId;
            us.RecordTypeId = usRtId;
            usw.selected = false;
            usw.removed = false;

            if (sw.userStories != null) {
                us.Order__c = 0;
                //usw.index = sw.userStories.size();
            } else {
                sw.userStories = new List<UserStoryWrapper>();
                //usw.index = sw.userStories.size();
                us.Order__c = 0;
            }
            Utilities.Secure_DML(us, Utilities.DML_Action.INS, schema.Sobjecttype.User_Story__c);
            pr = new PageReference('/' + us.Id + '/e');
            if (!isLightning) {
                pr.getParameters().put('retURL', '/' + sw.theSprint.Id);
            }
            return pr;


        } catch (exception e) {
            catchException(e);
            return pr;
        }
    }
    /*
        Method to be called to update all US on the Sprint
        for exmaple: reordering by drag and dropping
     */
    public PageReference dmlALL() {
        try {
            errorMessage = '';
            Map<String, User_Story__c> usToUpdate = new Map<String, User_Story__c>();
            for (UserStoryWrapper usw : sw.userStories) {
                if(!usw.removed){
                    if (String.valueOf(usw.theUS.Id) == '') { //the input secret makes this to be blank so it has to be reset
                        usw.theUS.Id = null;
                        //Now that offset is included, order must sum offSetCounter
                        if(usw.theUs.Order__c != null){
                           usw.theUs.Order__c = usw.theUs.Order__c + offSetCounter;
                        }
                    }
                    usToUpdate.put(usw.theUS.Id, usw.theUS);
                }
            }
            if (usToUpdate.size() > 0) {
                Utilities.Secure_DML(usToUpdate.values(), Utilities.DML_Action.UPS, schema.Sobjecttype.User_Story__c);
                refreshSprint(sw.sId);
            }
        } catch (exception e) {
            catchException(e);
        }
        return null;
    }
    /*
        Method called when updating a single row
     */
    public PageReference dmlRow() {
        Integer ind;
        try {
            errorMessage = '';
            User_Story__c usBackup = new User_Story__c();
            if (ApexPages.currentPage().getParameters().get('actionIndex') != null) {
                ind = Integer.valueOf(ApexPages.currentPage().getParameters().get('actionIndex'));
                system.debug(ind);
                sw.userStories[Integer.valueOf(ind)].theUS.RecordTypeId = rtWithId.get(sw.userStories[Integer.valueOf(ind)].rt);
                usBackup = sw.userStories[Integer.valueOf(ind)].theUS;
                system.debug(usBackup);
                //Add Cancelation Reason To allow users to cancel US from SprintWall
                if(sw.userStories[Integer.valueOf(ind)].theUS.Status__c == 'Cancelled'){
                    sw.userStories[Integer.valueOf(ind)].theUS.Cancellation_Reason__c = 'Cancelled by '+UserInfo.getName()+' Using the Sprint Wall';
                }
                Utilities.Secure_DML(sw.userStories[Integer.valueOf(ind)].theUS, Utilities.DML_Action.UPS, schema.Sobjecttype.User_Story__c);
            }
            system.debug(sw);
            calculateFilters();
        } catch (exception e) {
            catchException(e);
        }
        return null;
    }
    /*
        Method for New User Story button, record type is selected on the view
        using the radiobuttons and is set here
     */
    public PageReference createNewUSTask() {
        try {
            errorMessage = '';
            Integer ind = Integer.valueOf(actionIndex);
            system.debug(logginglevel.ERROR, actionIndex);
            USTaskWrapper utw = new USTaskWrapper();
            User_Story_Task__c ustToAdd = new User_Story_Task__c();
            ustToAdd.User_Story__c = sw.userStories[ind].theUS.Id;
            ustToAdd.Hours_Remaining__c = 0;            
            Utilities.Secure_DML(ustToAdd, Utilities.DML_Action.INS, schema.Sobjecttype.User_Story_Task__c);
            if(!ApexPages.hasMessages()){
                utw.theUSTask = ustToAdd;
                sw.userStories[Integer.valueOf(ind)].theTasks.get('Not Started').add(utw);                    
            }else{
                errorMessage = errorMessage + String.valueOf(ApexPages.getMessages());
            }
        } catch (exception e) {
            catchException(e);
        }
        return null;
    }
    /*
        Variables to store action function's parameters when updating or deleting
     */    
    
    private Integer i;
    private String bKey;
    private String aKey;
    private String tId;
    private String tField;
    private String tValue;


    /*
        Method to be called when drag and dropping User Story Tasks or updating them
     */
    public PageReference updateTaskStatusApex() {
        try {
            errorMessage = '';
            i = String.isNotBlank(ApexPages.currentPage().getParameters().get('rIndex')) ? Integer.valueOf(ApexPages.currentPage().getParameters().get('rIndex')) : null;
            bKey = String.isNotBlank(ApexPages.currentPage().getParameters().get('beforeKey')) ? ApexPages.currentPage().getParameters().get('beforeKey') : '';
            aKey = String.isNotBlank(ApexPages.currentPage().getParameters().get('afterKey')) ? ApexPages.currentPage().getParameters().get('afterKey') : '';
            tId = String.isNotBlank(ApexPages.currentPage().getParameters().get('taskID')) ? ApexPages.currentPage().getParameters().get('taskID') : '';
            tField = String.isNotBlank(ApexPages.currentPage().getParameters().get('tfield')) ? ApexPages.currentPage().getParameters().get('tfield') : '';
            tField = tField != null && !tField.startsWith(Settings.ns) && tField.endsWith('__c') ? Settings.ns + tField : tField;
            tValue = String.isNotBlank(ApexPages.currentPage().getParameters().get('tValue')) ? ApexPages.currentPage().getParameters().get('tValue') : '';
            integer taskIndex = 0;
            User_Story_Task__c ustToUpdate = new User_Story_Task__c();
            for (USTaskWrapper uw : sw.userStories[i].theTasks.get(bKey)) {
                system.debug(uw.theUSTask.Id);
                system.debug(tId);
                if (uw.theUSTask.Id == tId) {
                    system.debug(tId);
                    if (tField != null && tField != '') {
                        uw.theUSTask.put(tField, castValue(tField, tValue));
                    }

                    if (aKey != null && aKey != '') {
                        uw.theUSTask.Status__c = aKey;
                        sw.userStories[i].theTasks.get(aKey).add(uw);
                    }
                    ustToUpdate = uw.theUSTask;
                    break;
                }
                taskIndex++;
            }
            if (aKey != null && aKey != '') {
                sw.userStories[i].theTasks.get(bKey).remove(taskIndex);
            }
            Utilities.Secure_DML(ustToUpdate, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story_Task__c);
        } catch (exception e) {
            catchException(e);
        }
        return null;
    }
    /*
        Method called when clicking the X on each story task this DELETES the record
     */
    public PageReference deleteTask() {
        try {
            errorMessage = '';
            i = String.isNotBlank(ApexPages.currentPage().getParameters().get('rIndex')) ? Integer.valueOf(ApexPages.currentPage().getParameters().get('rIndex')) : null;
            bKey = String.isNotBlank(ApexPages.currentPage().getParameters().get('beforeKey')) ? ApexPages.currentPage().getParameters().get('beforeKey') : '';
            tId = String.isNotBlank(ApexPages.currentPage().getParameters().get('taskID')) ? ApexPages.currentPage().getParameters().get('taskID') : '';
            integer taskIndex = 0;
            User_Story_Task__c ustToDelete = new User_Story_Task__c();
            ustToDelete.Id = tId;
            for (USTaskWrapper uw : sw.userStories[i].theTasks.get(bKey)) {

                if (uw.theUSTask.Id == tId) {
                    break;
                }
                taskIndex++;
            }
            
            Utilities.Secure_DML(ustToDelete, Utilities.DML_Action.DEL, schema.Sobjecttype.User_Story_Task__c);
            if(!ApexPages.hasMessages()){            
                sw.userStories[i].theTasks.get(bKey).remove(taskIndex);            
            }else{
                errorMessage = errorMessage + String.valueOf(ApexPages.getMessages());
            }

        } catch (exception e) {
            catchException(e);
        }
        return null;
    }
    /*
        This is used to cast the value to the right type so the immediate method can
        pass value type and value and is set using the object .put() method
     */
    private object castValue (String fieldType, String fieldValue) {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.User_Story_Task__c.fields.getMap();
        DescribeFieldResult soDescribed = fieldMap.get(fieldType).getDescribe();
        if (soDescribed.getType() == Schema.DisplayType.String) {
            return fieldValue;
        } else if (soDescribed.getType() == Schema.DisplayType.Double) {
            return decimal.valueOf(fieldValue);
        } else if (soDescribed.getType() == Schema.DisplayType.Integer) {
            return Integer.ValueOf(fieldValue);
        }
        return null;
    }
    /*
        This is used to check if org has chatter enabled so chatter button is hidden
        and not rendered
     */
    public static boolean getisChatterEnabled() {
        return Schema.SObjectType.User.isFeedEnabled() && Schema.SObjectType.Sprint__c.isFeedEnabled();
    }

    private void catchException(exception e){
        errorMessage = e.getMessage();
        errorDetails = e.getStackTraceString();
        system.debug(logginglevel.ERROR, errorMessage);
        system.debug(logginglevel.ERROR, e.getStackTraceString());
    } 

    /*
        Data Structure for Sprint User Story and User Stories
        Ready to Scale if needed
     */
    public class SprintWrapper {
        Public String sId {get; set;}
        Public Sprint__c theSprint {get; set;}
        Public List<UserStoryWrapper> userStories {get; set;}
    }
    public class UserStoryWrapper {
        Public Boolean removed {get;set;}
        Public String rt {get; set;}
        Public Integer index {get; set;}
        Public Boolean selected {get; Set;}
        Public User_Story__c theUS {get; set;}
        Public Map<String, List<USTaskWrapper>> theTasks {get; set;}

    }
    public class USTaskWrapper {
        Public User_Story_Task__c theUSTask {get; set;}
    }
}