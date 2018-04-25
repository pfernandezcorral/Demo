/*
*   WorkManager Controller
*   Created by: jgaviria@copa.do
*   Test Class: WorkManagerTest
*   Description: Controller for WorkManager Page
*/
public with sharing class WorkManager {
    private Boolean hack_getPanelWrapperComingFromCreate = false;
    /**
     * View state control variable
     * @see totalSizeOK
     */
    public Integer totalUserStorySize {get; set;}
    /*
        List for the wrapper containing the Panels
     */
    public List<WrapperPanel> wpList {get; set;}
    /*
        List for the wrapper containing the Teams
     */
    public List<TWrapper> tWList {get; set;}
    /*
        This privatemap will help to find index given an Id
     */
    private Map<String, Integer> idWithIndex = new Map<String, Integer>();
    /*
        This privatemap will help to find index given the Name of a Panel State
     */
    private Map<String, Integer> nameWithIndex = new Map<String, Integer>();
    /*
        Aux Record to add panels related to an User Story
     */
    public User_Story__c auxUS {get; set;}
    /*
        select option for all the lookups of User Story
     */
    public List<SelectOption> usRelations {get; set;}
    /*
        select option for all the lookups of User Story
     */
    public List<SelectOption> usStatus {get; set;}
    /*
        String to Capture Option
     */
    public String relString {get; set;}
    /*
        String to Capture Panel Type
     */
    public String pTypeSelected {get; set;}
    /*
        String to Capture Status Value
     */
    public String statusSelected {get; set;}
    /*
        set to store all available User Story Status
     */
    private Set<String> allAvailable = new Set<String>();
    /*
        controller map for User Stories
     */
    private Map<String, User_Story__c> usMap = new Map<String, User_Story__c>();
    /*
        Set Of available Panels
     */
    public List<SelectOption> availablePanelStates {get; set;}
    /*
        list of PanelData to be stored as JSON on the current User Record
     */
    public UserStates uStates {get; set;}
    /*
    Map to get Relationship Value where no US on panel
     */
    private Map<String, String> apiRelWithApiName = new Map<String, String>();
    /*
    To check that user has at least a license enabled
     */
    public Boolean showWK {get; set;}
    /*
    String to query fieldset fields for user storys
     */
    private String availableColumns {get; set;}
    /*
    NameSpace 
	*/
    public String ns {get;set;}
    public WorkManager() {
        ns = Settings.ns;
        //create a string to query fields available
        getColumns();
        //see if current user can see Work Manager
        showWK = LicenseHelper.actionIsLicenseEnabled('WorkManager');
        //Sprints will be normally what Users will add
        relString = Settings.ns + 'Sprint__c';
        //memory to auxUS
        auxUS = new User_Story__c();
        //Initialize the apiRelMap
        getRelMap();
        //Initialize available Panels
        getAvailableStates();
        //Initialize usStatus
        getallusStatus();
        //Initialize SelectOptions
        getallSelectOptions();
        //Get all possible Teams
        getAllTeams();
        //Try to get JSON
        if (uStates.panelData.size() > 0) {
            getUserStatePanels(uStates.lastState);
        } else {
            //Try to get the 4 Standard Panels
            getDefaultUserStories();
        }
    }
    /*
        Method to set availableColumns with fields from fieldset
     */
    private void getColumns() {
        availableColumns = '';
        usRelations = new List<SelectOption>();
        List<Schema.FieldSetMember> fSM = SObjectType.User_Story__c.FieldSets.Work_Manager_Columns.getFields();
        for (Schema.FieldSetMember fS : fSM) {
            availableColumns = availableColumns + fS.getFieldPath() + ', ';
        }
    }

    /*
        Map to know name the API name of the related custom object
     */

    private void getRelMap() {
        Schema.DescribeSObjectResult d =  User_Story__c.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fsMap =  d.fields.getMap();
        for (Schema.SObjectField fS : fsMap.values()) {
            Schema.DescribeFieldResult dResult = fS.getDescribe();
            if (dResult.isAccessible() && String.valueOf(dResult.getType()) == 'REFERENCE' && dResult.isUpdateable()) {
                apiRelWithApiName.put(dResult.getName(), String.ValueOf(dResult.getReferenceTo()[0]));
            }
        }
    }
    /*
        Given the JSON, render panels
     */
    public PageReference refreshState() {
        getUserStatePanels(pTypeSelected);
        return null;
    }
    /*
        This method will fill all the panels given a state configuration
     */
    private void getUserStatePanels (String lState) {
        wpList = new List<WrapperPanel>();
        idWithIndex = new Map<String, Integer>();
        for (PanelData pd : uStates.panelData) {
            if (pd.pName == lState) {
                Integer j = 0;
                //system.debug(pd);
                for (PWrapper p : pd.pWrappers) {
                    //system.debug(p.pType);
                    //system.debug(p.pId);
                    //system.debug(Settings.ns+'Status__c');
                    List<WrapperPanel> wpListState = new List<WrapperPanel>();
                    if (p.pType == Settings.ns + 'Status__c') {
                        wpListState.add(buildStatusPanels(p.pId, p.columns));
                        idWithIndex.put(Settings.ns + 'Status__c' + '.' + p.pId, j);
                    } else {
                        //system.debug(p.pId);
                        wpListState.add(getPanelWrapper(p.pId, p.pType, p.columns));
                        idWithIndex.put(p.pType + '.' + p.pId, j);
                    }
                    j++;
                    if (!totalSizeOK(wpListState)) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'Too many records. Please re-arrange the panels!'));
                        break;
                    } else {
                        wpList.addAll(wpListState);
                    }
                }
                break;
            }
        }
        //system.debug(wpList);
    }
    /*
        This Method tries to retrieve Configuration for current user, otherwise starts
        the flow by adding a Default State
     */
    private void getAvailableStates() {
        availablePanelStates = new List<SelectOption>();
        uStates = new UserStates();
        List<User> currentUser = [Select Work_Manager_Panels__c From User Where Id = :UserInfo.getUserId()];
        if (currentUser.size() > 0 && currentUser[0].Work_Manager_Panels__c != '' && isValid(currentUser[0].Work_Manager_Panels__c)) {
            uStates = (UserStates)JSON.deserialize(currentUser[0].Work_Manager_Panels__c, UserStates.class);
            pTypeSelected = uStates.lastState != null ? uStates.lastState : 'Default';
            for (PanelData pd : uStates.panelData) {
                availablePanelStates.add(new SelectOption(pd.pName, pd.pName));
            }
        } else {
            availablePanelStates.add(new SelectOption('Default', 'Default'));
            pTypeSelected = 'Default';
            //system.debug('Wrong JSON, starting from scratch');
        }
    }
    /*
        This Method will reorder the pannels in the wrapper and update the User Field with the Json
     */
    public PageReference savePanelState() {
        try {
            //Clear List
            idWithIndex.clear();
            String jUpdate = (String.isNotBlank(ApexPages.currentPage().getParameters().get('jsstate')) ? String.valueOf(ApexPages.currentPage().getParameters().get('jsstate')) : '');
            System.debug(loggingLevel.Info, '*** jUpdate: ' + jUpdate);
            PanelData jsonObj = new PanelData();
            jsonObj = (PanelData)JSON.deserialize(jUpdate, PanelData.class);
            System.debug(loggingLevel.Info, '*** jsonObj: ' + jsonObj);
            jsonObj.pName = pTypeSelected;
            Integer i = 0;
            Boolean found = false;
            for (PanelData pd : uStates.panelData) {
                if (pd.pName == pTypeSelected) {
                    found = true;
                    break;
                }
                i++;
            }
            //system.debug(uStates.panelData);
            if (uStates.panelData.size() > 0 && found) {
                uStates.panelData[i] = jsonObj;
            } else {
                uStates.panelData.add(jsonObj);
            }
            UserStates uState = new UserStates();
            uState.lastState = pTypeSelected;
            uState.panelData = uStates.panelData;
            //system.debug(uState);
            String jsonString = Json.serialize(uState);
            //system.debug(jsonString);
            User u = new User();
            u.Id = UserInfo.getUserId();
            u.Work_Manager_Panels__c = jsonString;
            System.debug(loggingLevel.Info, '*** u: ' + u);
            Utilities.Secure_DML(u, Utilities.DML_Action.UPD, schema.Sobjecttype.User);
            //Now Try To Reorder the master Wrapper
            List<WrapperPanel> wpListAux = new List<WrapperPanel>();
            Integer j = 0;
            for (pWrapper pW : jsonObj.pWrappers) {
                for (WrapperPanel wp : wpList) {
                    if (pW.pId == wp.recordId && pW.pType == wp.pType) {
                        for (String wpCol : wp.rColumns.keySet()) {
                            wp.rColumns.put(wpCol, false);
                            for (String col : pw.columns) {
                                if (wp.rColumns.containsKey(col)) {
                                    wp.rColumns.put(col, true);
                                }
                            }
                        }
                        System.debug(loggingLevel.Info, '*** wp: ' + wp);
                        wpListAux.add(wp);
                        idWithIndex.put(wp.pType + '.' + wp.recordId, j);
                    }
                }
                j++;
            }
            wpList.clear();
            wpList.addAll(wpListAux);
            //wpList = wpListAux;
            //system.debug(idWithIndex);
            //system.debug(wpList);
        } catch (Exception e) {
            system.debug(e.getMessage());
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
    /*
        Given Name from config add new one to select options and select it
     */
    public PageReference addNewConfig() {
        String nPanelName = (String.isNotBlank(ApexPages.currentPage().getParameters().get('sName')) ? String.valueOf(ApexPages.currentPage().getParameters().get('sName')) : '');
        availablePanelStates.add(new SelectOption(nPanelName, nPanelName));
        pTypeSelected = nPanelName;
        return null;
    }
    /*
        With The name of the actual config, delete it and redirect to Default
     */
    public PageReference removeConfig() {
        try {
            if (pTypeSelected != '' && pTypeSelected != 'Default') {
                // remove from 2 lists and change to Default
                if (uStates.panelData != null) {
                    for (Integer j = uStates.panelData.size() - 1; j >= 0;  j--) {
                        if (pTypeSelected == uStates.panelData[j].pName) {
                            uStates.panelData.remove(j);
                            break;
                        }
                    }
                    for (Integer j = availablePanelStates.size() - 1; j >= 0;  j--) {
                        if (pTypeSelected == availablePanelStates[j].getValue()) {
                            availablePanelStates.remove(j);
                            break;
                        }
                    }
                }
                pTypeSelected = 'Default';
                //Last State Back to Default
                uStates.lastState = 'Default';
                //Update on User
                String jsonString = Json.serialize(uStates);
                //system.debug(jsonString);
                User u = new User();
                u.Id = UserInfo.getUserId();
                u.Work_Manager_Panels__c = jsonString;
                Utilities.Secure_DML(u, Utilities.DML_Action.UPD, schema.Sobjecttype.User);
                refreshState();
            }
        } catch (Exception e) {
            system.debug(e.getMessage());
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
    /*
        Method to try to parse User Field as JSON
     */
    private boolean isValid(String jsonString) {
        try {
            UserStates pdValid = new UserStates();
            pdValid = (UserStates)JSON.deserialize(jsonString, UserStates.class);
            return true;
        } catch (Exception e) {
            system.debug('*** isValid :::' + e.getMessage() + ':::stackTrace' + e.getStackTraceString());
            return false;
        }
    }
    /*
        All User Stories with Status Backlog and Backburner will be retrieved here
        also all the User Stories for the current Sprint and next Sprint
     */
    private void getallSelectOptions() {
        usRelations = new List<SelectOption>();
        List<Schema.FieldSetMember> fSM = SObjectType.User_Story__c.FieldSets.Work_Manager_Relations.getFields();
        for (Schema.FieldSetMember fS : fSM) {
            //system.debug(fS);
            if (String.valueOf(fS.getType()) == 'REFERENCE') {
                usRelations.add(new SelectOption(fS.getFieldPath(), fS.getLabel()));
                if (String.isBlank(relString)) {
                    relString = fS.getFieldPath();
                }
            }
        }
        usRelations.sort();
        //Add Status Option
        usRelations.add(new SelectOption(Settings.ns + 'Status__c', 'Status'));
    }
    /*
        Describe User Story Status to create Status pannels
     */
    private void getallusStatus() {
        usStatus = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = User_Story__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for ( Schema.PicklistEntry f : ple) {
            usStatus.add(new SelectOption(f.getLabel(), f.getValue()));
            allAvailable.add(f.getValue());
        }
    }
    /*
        Clear auxUS when user picks another lookup
     */
    public PageReference clearAuxUS() {
        auxUS = new User_Story__c();
        return null;
    }
    /*
        If Backlog and Backburner Exist Add them
        also if user is part of Team and there is current and next sprint, add them
     */
    private void getDefaultUserStories() {
        wpList = new List<WrapperPanel>();
        //Add first two pannels to wrapper list
        if (allAvailable.contains('Backlog')) {
            wpList.add(buildStatusPanels('Backlog', null));
        }
        if (allAvailable.contains('Backburner')) {
            wpList.add(buildStatusPanels('Backburner', null));
        }
        //Add The current and next sprint, if they exist
        List<Sprint__c> sList = getCurrentAndNextSprint();
        Integer index = wpList.size();//Because Backlog and Backburner are static
        for (Sprint__c s : sList) {
            wpList.add(getPanelWrapper(s.Id, Settings.ns + 'Sprint__c', null));
            idWithIndex.put(Settings.ns + 'Sprint__c' + '.' + s.Id, index);
            index++;
        }
        //system.debug(wpList);
    }
    /*
        Will return current sprint in index 0 and next in index 1,
        if there is more than 1 sprint for the current date and  one of them is the team of current user that will be shown
        otherwise, the first one
     */
    private List<Sprint__c> getCurrentAndNextSprint() {
        List<Sprint__c> lToReturn = new List<Sprint__c>();
        Date today = Date.today();
        Set<Id> userTeamIds = getCurrentUserTeams(tWList);
        //system.debug(userTeamIds);
        List<Sprint__c> currentSprintList = [SELECT Id, Name, Team__c, End_Date__c
                                             FROM Sprint__c
                                             WHERE Start_Date__c <= : today
                                             AND End_Date__c >= : today
                                             AND(Team__c IN : userTeamIds OR Team__c = null)
                                             ORDER BY Team__c
                                             NULLS LAST
                                             LIMIT 1];
        //If there is a current sprint for User's Id or Sprints have no team
        if (currentSprintList.size() > 0) {
            lToReturn.add(currentSprintList[0]);
            //Now we find The Next Sprint, if the team was set it should start after current's end date
            List<Sprint__c> nextSprintList = [SELECT Id, Name, Team__c
                                              FROM Sprint__c
                                              WHERE Start_Date__c >= : currentSprintList[0].End_Date__c
                                              AND Id != : currentSprintList[0].Id
                                              AND (Team__c = : currentSprintList[0].Team__c OR Team__c = null)
                                              ORDER BY Team__c
                                              NULLS LAST
                                              LIMIT 1];
            //system.debug(nextSprintList);
            if (nextSprintList.size() > 0) {
                lToReturn.add(nextSprintList[0]);
            }
        }
        //system.debug(lToReturn);
        return lToReturn;
    }
    /*
        retuns a set of Team Ids where the user is a team member
     */
    private static Set<Id> getCurrentUserTeams(List<TWrapper> tW) {
        Set<Id> sToReturn = new Set<Id>();
        for (TWrapper t : tW) {
            if (t.myTeam) {
                sToReturn.add(t.t.Id);
            }
        }
        return sToReturn;
    }
    /*
        Find all the available teams and mark the ones that the current user belongs to as my team
    */
    private void getAllTeams() {
        tWList = new List<TWrapper>();
        List<Team__c> allTeams = [SELECT Id, Name,
                                  (SELECT Id, Member__c FROM Team_Members__r)
                                  FROM Team__c
                                  WHERE Active__c = true];
        Id uId = UserInfo.getUserId();
        //system.debug(allTeams);
        //system.debug(uId);
        for (Team__c t : allTeams) {
            TWrapper tAdd = new TWrapper(t, false);
            for (Team_Member__c tm : t.Team_Members__r) {
                if (tm.Member__c == String.valueOf(uId)) {
                    tAdd.myTeam = true;
                    //is my team, no need to check anymore
                    break;
                } else {
                    tAdd.myTeam = false;
                }
            }
            tWList.add(tAdd);
        }
    }
    /*
        JSON will be received containing Backlog and Backburner Ranks
    */
    public PageReference updateRanks() {
        try {
            if (!totalSizeOK(new WrapperPanel())) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'Too many records. Please re-arrange the panels!'));
                return null;
            }
            Map<String, User_Story__c> mUS = new Map<String, User_Story__c>();
            String jUpdate = (String.isNotBlank(ApexPages.currentPage().getParameters().get('jsrank')) ? String.valueOf(ApexPages.currentPage().getParameters().get('jsrank')) : '');
            //system.debug(jUpdate);
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jUpdate);
            //system.debug(idWithIndex);
            //system.debug(wpList);
            if (idWithIndex.containsKey(Settings.ns + 'Status__c' + '.' + 'Backlog') && idWithIndex.containsKey(Settings.ns + 'Status__c' + '.' + 'Backlog') && wpList[idWithIndex.get(Settings.ns + 'Status__c' + '.' + 'Backlog')].usList != null) {
                List<Object> blList = (List<Object>)m.get('logIds');
                if (blList.size() > 0) {
                    Integer i = 1;
                    for (Object o : blList) {
                        //system.debug(o);
                        //system.debug(uw.us);
                        User_Story__c us = new User_Story__c();
                        us.Id = String.valueOf(o);
                        us.Backlog_Rank__c = i;
                        us.Backburner_Rank__c = null;
                        us.Order__c = null;
                        mUS.put((String)us.Id, us);
                        i++;
                    }
                }
            }
            if (idWithIndex.containsKey(Settings.ns + 'Status__c' + '.' + 'Backburner') && idWithIndex.containsKey(Settings.ns + 'Status__c' + '.' + 'Backburner') && wpList[idWithIndex.get(Settings.ns + 'Status__c' + '.' + 'Backburner')].usList != null) {
                List<Object> blList = (List<Object>)m.get('burnerIds');
                if (blList.size() > 0) {
                    Integer i = 1;
                    for (Object o : blList) {
                        User_Story__c us = new User_Story__c();
                        us.Id = String.valueOf(o);
                        us.Backburner_Rank__c = i;
                        us.Backlog_Rank__c = null;
                        us.Order__c = null;
                        mUS.put((String)us.Id, us);
                        i++;
                    }
                }
            }

            List<Object> sList = (List<Object>)m.get('sprintWithOrder');
            if (sList.size() > 0) {
                for (Integer i = 0; i < sList.size(); i++) {
                    //system.debug(s);
                    Map<String, Object> sP = (Map<String, Object>)sList[i];
                    system.debug(sP);
                    List<Object> usIds = (List<Object>)sP.get('usIds');
                    Integer j = 1;
                    for (Object us : usIds) {
                        User_Story__c u = new User_Story__c();
                        u.Id = String.valueOf(us);
                        u.Backburner_Rank__c = null;
                        u.Backlog_Rank__c = null;
                        u.Order__c = j;
                        mUS.put((String)u.Id, u);
                        j++;
                    }
                }
            }

            system.debug('*** updateRanks:::mUS.values() general' + mUS.values());
            Utilities.Secure_DML(mUS.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
        } catch (Exception e) {
            system.debug('*** updateRanks:::catch' + e.getMessage());
            system.debug('*** updateRanks:::catch' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
    /*
        a JSON will be built with javascript and this method will update the panels accordinly
     */
    public PageReference updatePanels() {
        try {
            //see if jsRank is there, calcualate ranks first
            String jRank = (String.isNotBlank(ApexPages.currentPage().getParameters().get('jsrank')) ? String.valueOf(ApexPages.currentPage().getParameters().get('jsrank')) : '');
            system.debug('*** jRank : ' + jRank);
            if (String.isNotBlank(jRank)) {
                updateRanks();
            }
            String jUpdate = (String.isNotBlank(ApexPages.currentPage().getParameters().get('jsonUpdate')) ? String.valueOf(ApexPages.currentPage().getParameters().get('jsonUpdate')) : '');
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jUpdate);
            system.debug('*** jUpdate : ' + jUpdate);
            String sId = String.valueOf(m.get('sId'));
            String tId = String.valueOf(m.get('tId'));
            String stype = String.valueOf(m.get('stype'));
            String ttype = String.valueOf(m.get('ttype'));
            Boolean beingCancelled = tId == 'Cancelled';
            //(1) US are changing status
            if (allAvailable.contains(sId) && allAvailable.contains(tId)) {
                //Try to do DML, if ok, then remove from sId and add to tId
                List<User_Story__c> usToUpdate = new List<User_Story__c>();
                map<String, String> usIdSet = new map<String, String>();
                for (Object usId : (List<Object>)m.get('usIds')) {
                    String uId = String.valueOf(usId);
                    usIdSet.put(uId, tId);
                    User_Story__c u = new User_Story__c();
                    u.Id = uId;
                    u.Status__c = tId;
                    if (beingCancelled) {
                        u.Cancellation_Reason__c = 'Cancelled by ' + UserInfo.getName() + ' Using the Work Manager';
                    }
                    usToUpdate.add(u);
                }
                Utilities.Secure_DML(usToUpdate, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
                System.debug(loggingLevel.Error, '*** update usToUpdate 1: ' + usToUpdate);
                refreshState();
            }
            //(2) From Status to Relation, Relation to Status and Relation to Relation
            else if ( allAvailable.contains(sId) && !allAvailable.contains(tId) ||
                      !allAvailable.contains(sId) && allAvailable.contains(tId) ||
                      !allAvailable.contains(sId) && !allAvailable.contains(tId)  ) {
                List<User_Story__c> usToUpdate = new List<User_Story__c>();
                set<String> usIdSet = new set<String>();
                //system.debug(ttype);
                //system.debug(tId);
                for (Object usId : (List<Object>)m.get('usIds')) {
                    String uId = String.valueOf(usId);
                    User_Story__c u = usMap.get(uId);
                    usIdSet.add(uId);
                    u.Id = uId;
                    u.put(ttype, tId);
                    if (beingCancelled) {
                        u.Cancellation_Reason__c = 'Cancelled by ' + UserInfo.getName() + ' Using the Work Manager';
                    }
                    usToUpdate.add(u);
                }
                system.debug(usToUpdate);
                Utilities.Secure_DML(usToUpdate, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
                System.debug(loggingLevel.Error, '*** update usToUpdate 2: ' + usToUpdate);
                refreshState();
            }
        } catch (Exception e) {
            system.debug('*** updatePanels:::catch : ' + e.getMessage() + ':::stackTrace' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
    /*
        Method to add New Panel to Work Manager
     */
    private Boolean totalSizeOK(WrapperPanel wp) {
        return totalSizeOK(new List<WrapperPanel> {wp});
    }
    private Boolean totalSizeOK(List<WrapperPanel> wpanelList) {
        totalUserStorySize = 0;
        for (WrapperPanel wp : wpList) {
            if (wp.usList != null && !wp.usList.isEmpty()) {
                totalUserStorySize += wp.usList.size();
            }
        }
        for (WrapperPanel wpe : wpanelList) {
            if (wpe.usList != null && !wpe.usList.isEmpty()) {
                totalUserStorySize += wpe.usList.size();
            }
        }
        System.debug(loggingLevel.INFO, '*** totalUserStorySize: ' + totalUserStorySize);
        if (totalUserStorySize < 1400) {
            return true;
        }
        return false;
    }
    public PageReference createNewPanel() {

        try {
            String panelId = (String.isNotBlank(ApexPages.currentPage().getParameters().get('newPanelId')) ? String.valueOf(ApexPages.currentPage().getParameters().get('newPanelId')) : '');
            String panelName = (String.isNotBlank(ApexPages.currentPage().getParameters().get('newPanelName')) ? String.valueOf(ApexPages.currentPage().getParameters().get('newPanelName')) : '');
            System.debug(loggingLevel.Error, '*** panelId: ' + panelId);
            System.debug(loggingLevel.Error, '*** panelName: ' + panelName);
            Boolean isStatus = false;
            if (String.isNotBlank(panelId)) {
                //conver to 18Digit
                panelId = String.ValueOf((Id)panelId);
            }
            if (String.isBlank(panelId) && String.isNotBlank(statusSelected)) {
                panelId = statusSelected;
                isStatus = true;
            }
            system.debug('*** after convert panelID :' + panelId);
            //system.debug(panelName);
            System.debug(loggingLevel.Error, '*** idWithIndex: ' + idWithIndex);
            System.debug(loggingLevel.Error, '*** idWithIndex.containsKey(panelName.panelId): ' + idWithIndex.containsKey(panelName + '.' + panelId));
            if (panelId != '' && !idWithIndex.containsKey(panelName + '.' + panelId)) {
                system.debug('Entered' + panelId + ':::' + panelName);
                WrapperPanel w = new WrapperPanel();
                if (isStatus) {
                    w = buildStatusPanels(panelId, null);
                } else {
                    hack_getPanelWrapperComingFromCreate = true;
                    w = getPanelWrapper(panelId, panelName, null);
                    hack_getPanelWrapperComingFromCreate = false;
                }
                if (!totalSizeOK(w)) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'Too many records. Please re-arrange the panels!'));
                    return null;
                }
                wpList.add(w);
                idWithIndex.put(panelName + '.' + panelId, wpList.size() - 1);
            }

        } catch (Exception e) {
            system.debug('*** createNewPanel ::: + ' + e.getMessage() + ':::stackTrace' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
    /*
        Method to Hide Panel given
     */
    public PageReference hidePanel() {
        String pId = (String.isNotBlank(ApexPages.currentPage().getParameters().get('panelId')) ? String.valueOf(ApexPages.currentPage().getParameters().get('panelId')) : '');
        String pT = (String.isNotBlank(ApexPages.currentPage().getParameters().get('panelType')) ? String.valueOf(ApexPages.currentPage().getParameters().get('panelType')) : '');

        try {
            Integer index = idWithIndex.get(pT + '.' + pId);
            system.debug(index);
            if (wpList.size() > index - 1) {
                wpList.remove(index);
            }
        } catch (Exception e) {
            System.debug('hidePanel::catch: ' + e.getMessage() + '::stackTrace' + e.getStackTraceString());
        }

        return null;
    }
    /*
        Given API name of colum, make it visble
     */
    public PageReference toggleColumn() {
        String cN = (String.isNotBlank(ApexPages.currentPage().getParameters().get('cName')) ? String.valueOf(ApexPages.currentPage().getParameters().get('cName')) : '');
        String pId = (String.isNotBlank(ApexPages.currentPage().getParameters().get('panelId')) ? String.valueOf(ApexPages.currentPage().getParameters().get('panelId')) : '');
        String pT = (String.isNotBlank(ApexPages.currentPage().getParameters().get('panelType')) ? String.valueOf(ApexPages.currentPage().getParameters().get('panelType')) : '');
        Integer index = idWithIndex.get(pT + '.' + pId);
        system.debug(index);
        system.debug(cN);
        system.debug(pId);
        system.debug(pT);
        system.debug(wpList[index].rColumns);

        if (wpList.size() > index - 1) {
            wpList[index].rColumns.put(cN, !wpList[index].rColumns.get(cN));
        }
        return null;
    }

    /*
        Given Id, generate the wrapper Panel for all user stories related to this
     */
    private WrapperPanel getPanelWrapper(Id objId, String objName, List<String> cols) {
        System.debug(loggingLevel.Error, '*** objId: ' + objId);
        System.debug(loggingLevel.Error, '*** objName: ' + objName);
        System.debug(loggingLevel.Error, '*** cols: ' + cols);
        String qOrder = 'ORDER BY Name';
        if (objName == Settings.ns + 'Sprint__c') {
            qOrder = 'ORDER BY Order__c';
        }
        WrapperPanel wP = new WrapperPanel();
        String relatedAPI = objName;
        String relationAPI = relatedAPI.replace('__c', '__r');
        String q = 'SELECT ' + availableColumns + ' Id, Name ';
        q = !q.contains(relationAPI + '.Name') ? q + ', ' + relationAPI + '.Name ' : q;
        q = q + 'FROM User_Story__c ' +
            'WHERE ' + relatedAPI + ' =: objId ' +
            qOrder;
        q += ' LIMIT 200';
        System.debug(loggingLevel.Error, '*** getPanelWrapper:::queryStr: ' + q);
        List<User_Story__c> usList = Database.query(q);
        wP.rColumns = getColumnsforList(cols);
        if (usList.size() > 0) {
            wP.title =     String.valueOf(usList[0].getSObject(relationAPI).get('Name'));
            wP.recordId =     String.valueOf((Id)usList[0].get(relatedAPI));
            wP.hidden = false;
            wP.pType = relatedAPI;
            wP.usList = new List<UWrapper>();
            for (User_Story__c u : usList) {
                usMap.put(u.Id, u);
                UWrapper uW = new UWrapper();
                uW.us = u;
                // due to double quote issues, we need this hack
                if(hack_getPanelWrapperComingFromCreate){
                    uW.us.User_Story_Title__c = uW.us.User_Story_Title__c==null?null:uW.us.User_Story_Title__c.replace('"','``');
                }
                wP.usList.add(uW);
            }
        } else {
            //Looking for US in the top query, if they don't exist must query name from record
            List<SObject> pRecord = Database.query('SELECT Id, Name From ' + apiRelWithApiName.get(relatedAPI) + ' where Id =: objId');
            if (pRecord.size() > 0) {
                wP.title =     String.ValueOf(pRecord[0].get('Name'));
            }
            wP.recordId =     objId;
            wP.hidden = false;
            wP.pType = relatedAPI;
            wP.usList = new List<UWrapper>();
        }
        system.debug(wP.rColumns);
        return wP;
    }
    /*
        This is to populate the two first Panels for Backlog and Backburner
     */
    private WrapperPanel buildStatusPanels(String status, List<String> cols) {
        //init Panels
        String qFilter = 'WHERE Status__c = : status ';
        if (status == 'Backlog') {
            qFilter = 'WHERE Status__c != \'Backburner\'  AND Status__c != \'Cancelled\' AND Status__c != \'Rejected\' AND Sprint__c = null';
        } else if (status == 'Backburner') {
            qFilter = 'WHERE Status__c = \'Backburner\' AND Sprint__c = null';
        }
        system.debug('*** buildStatusPanels : ' + status);
        WrapperPanel wp = initPanel(status);
        String q = 'SELECT ' + availableColumns + ' Id, Name ' +
                   'FROM User_Story__c ' +
                   qFilter +
                   ' ORDER BY Backlog_Rank__c, Backburner_Rank__c, Name LIMIT 200';
        System.debug(loggingLevel.INFO, '*** buildStatusPanels q: ' + q);
        List<User_Story__c> usList = Database.query(q);
        //system.debug(usList);
        //system.debug(statWithWrapperPanel);
        wP.rColumns = getColumnsforList(cols);
        if (usList.size() > 0) {
            for (User_Story__c u : usList) {
                usMap.put(u.Id, u);
                UWrapper uW = new UWrapper();
                uW.selected = false;
                uW.us = u;
                wp.usList.add(uW);
            }
        }
        System.debug(loggingLevel.INFO, '*** buildStatusPanels wp: ' + wp.usList);
        return wp;
    }
    /*
        give memory and fill maps for Default Panels
     */
    private WrapperPanel initPanel(String s) {
        WrapperPanel wPAux = new WrapperPanel();
        wPAux.title = s;
        wPAux.hidden = false;
        wPAux.pType = Settings.ns + 'Status__c';
        wPAux.recordId = s;
        wPAux.usList = new List<UWrapper>();
        idWithIndex.put(Settings.ns + 'Status__c' + '.' + s, wpList.size());
        return wPAux;
    }
    /*
    Given list of api names, set up the map to show columns
     */
    private map<String, Boolean> getColumnsforList(List<String> cols) {
        map<String, Boolean> mToReturn = new map<String, Boolean>();
        List<Schema.FieldSetMember> fSM = SObjectType.User_Story__c.FieldSets.Work_Manager_Columns.getFields();
        for (Schema.FieldSetMember fS : fSM) {
            mToReturn.put(fS.getFieldPath(), false);
        }
        if (cols != null && cols.size() >= 0) {
            for (String s : cols) {
                mToReturn.put(s, true);
            }
        } else {
            mToReturn.put(Settings.ns + 'User_Story_Title__c', true);
            mToReturn.put(Settings.ns + 'Story_Points_SFDC__c', true);
        }
        system.debug(mToReturn);
        return mToReturn;
    }
    /*
        This is the data structure defined to show every panel on the page
     */
    public class WrapperPanel {
        public Boolean hidden {get; set;}
        public String title {get; set;}
        public String pType {get; set;}
        public String recordId {get; set;}
        public List<UWrapper> usList {get; set;}
        public map<String, Boolean> rColumns {get; set;} //Used to render or not columns
        public WrapperPanel () {}
    }
    /*
        User Story Wrapper
     */
    public class UWrapper {
        public Boolean selected {get; set;}
        public User_Story__c us {get; set;}
    }
    /*
        Team wrapper
     */
    public class TWrapper {
        public Boolean myTeam {get; set;}
        public Team__c t {get; set;}
        public TWrapper(Team__c t, Boolean mT) {
            this.t = t;
            this.myTeam = mT;
        }
    }
    public class UserStates {
        public String lastState {get; set;}
        List<PanelData> panelData {get; set;}
        public UserStates() {
            this.panelData = new List<PanelData>();
        }
    }
    public class PanelData {
        public String pName {get; set;}
        public Set<pWrapper> pWrappers {get; set;}
        public PanelData() {
            this.pWrappers = new Set<pWrapper>();
        }
    }
    public class PWrapper {
        public String pId {get; set;}
        public String pType {get; set;}
        public List<String> columns {get; set;}
    }
}