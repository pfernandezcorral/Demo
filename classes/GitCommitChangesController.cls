global with sharing class GitCommitChangesController{

    public Git_Org_Commit__c gitCommit{get;set;}

    public String repositoryId {get;set;}
    public String snapshotId {get;set;}
    public String orgId {get;set;}
    public String userStoryId {get;set;}

    public String orgName {get;set;}
    public String repoName {get;set;}
    public String branch {get;set;}

    public Git_Backup__c gitBackup {get;set;}
    public User_Story__c userStory {get;set;}
    public boolean showSnapshotInformation{get;set;}
    public boolean isDXEnabled {get; set;}
    public Boolean showVlocity {get; set;}
    public String errorDetails {get; set;}

    public String artifactsParentOrgId {get;set;}

    public List<Schema.FieldSetMember> getFields() {
        List<Schema.FieldSetMember> fields = SObjectType.Git_Backup__c.FieldSets.Commit_Files_Information.getFields();
        showSnapshotInformation = fields.size()>0;
        return fields;
    }
    public List<Schema.FieldSetMember> getUSFields() {
        return SObjectType.User_Story__c.FieldSets.Commit_Files_Information.getFields();
    }

    // Advanced
    public String baseBranch {get;set;}
    public Boolean showBaseBranch {get;set;}

    // Git Operations variables
    public Map<String, Operation> operationsMap {get;set;}
    public List<SelectOption> operationTypes {get;set;}
    public Operation selectedOperation {get;set;}
    public List<SnapshotCommitWrapper> snapshotCommitWrappers {get;set;}
    public String gitMetadataAttachmentId {get;set;}
    public String possibleRunningJobs {get;set;}

    /**
     * constructor
     * @return [description]
     */
    public GitCommitChangesController() {
        // get from parameter the related snapshot
        Map<String, String> params = ApexPages.currentPage().getParameters();

        repositoryId = params.get('repoId');
        snapshotId = params.get('snapshotId');
        orgId = params.get('orgId');
        baseBranch = '';
        showBaseBranch = false;
        userStoryId = params.get('userStoryId');
        
        String Commit_Message = '';
        if(String.isNotEmpty(userStoryId)) {
            isDXEnabled = SfdxAPIHelper.isDXEnabledForUSDeploymentFlow(userStoryId);
            // get values for userStory fields and commit message
            try {
                String query = 'SELECT ';
                for(Schema.FieldSetMember f : this.getUSFields()) {
                    String fp = f.getFieldPath();
                    if(fp != 'Name') {
                        query += fp + ', ';
                    }
                }
                query += 'Release__r.Version__c, ';
                query += 'Name FROM User_Story__c WHERE Id =:userStoryId LIMIT 1';
                userStory = Database.query(query);
            } catch (Exception e) {
                catchException(e);
            }
            for( User_Story__c us : [SELECT Name, User_Story_Title__c  FROM User_Story__c WHERE Id =:userStoryId]) {
                Commit_Message = (us.Name +': ' + (String.isEmpty(us.User_Story_Title__c)?'': us.User_Story_Title__c)).left(254);
            }
        } else {
            showBaseBranch = false;
        }

        // get values snapshot fields and subtitle
        try {
            String query = 'SELECT ';
            for(Schema.FieldSetMember f : this.getFields()) {
                String fp = f.getFieldPath();
                if(fp != 'Git_Repository__r.Name')  {
                    query += fp + ', ';
                }
            }
            query += ' Org__r.Org_Type__c, ';
            query += ' Git_Repository__r.Name FROM Git_Backup__c WHERE Id =:snapshotId LIMIT 1';
            gitBackup = Database.query(query);
        } catch (Exception e) {
            catchException(e);
        }

        //Artifacts: If there is a Scratch Org associated and commit is done from US, try to get the Parent Org of the loaded artifacts
        if(String.isNotBlank(orgId) && String.isNotBlank(userStoryId) && gitBackup != null && gitBackup.Org__r.Org_Type__c != null && gitBackup.Org__r.Org_Type__c == 'Scratch Org'){
            artifactsParentOrgId = SfdxAPIHelper.getSOartifactParentId(orgId);
            if(String.isNotBlank(artifactsParentOrgId) && (userStory.Release__c == null || userStory.Release__r.Version__c == null)){
                system.debug('No Release Found');
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.USER_STORY_RELEASE_VERSION_MISSING)); //TODO DX LABEL
            }
        }


        Git_Backup__c snapshot = [SELECT Org__r.Name, Branch__c, Git_Repository__r.Name FROM Git_Backup__c WHERE Id =:snapshotId ];
        orgName = snapshot.Org__r.Name;
        repoName = snapshot.Git_Repository__r.Name;
        branch = snapshot.Branch__c;

        // create a fake commit record
        gitCommit = new Git_Org_Commit__c(
                Git_Backup__c = snapshotId,
                Org__c = orgId,
                Commit_Message__c = Commit_Message
        );

        // Get Base Branch
        getBaseBranch();

        // Init Git Operations
        operationsMap = new Map<String, Operation>();
        operationTypes = new List<SelectOption>();
        Operation commitFilesOperation = new Operation();
        commitFilesOperation.operationLabel = 'Commit Files';
        commitFilesOperation.operationType = 'CommitFiles';
        commitFilesOperation.showGrid = true;
        commitFilesOperation.editGrid = false;
        commitFilesOperation.showCommitMessage = true;
        commitFilesOperation.endpoint = 'commit';
        commitFilesOperation.pages = 'GitSnapshotCommit,UserStoryCommit';
        commitFilesOperation.showAdvancedSection = true;
        gitCommit.Git_Operation__c = 'Commit Files';

        operationsMap.put(commitFilesOperation.operationLabel, commitFilesOperation);
        operationTypes.add(new SelectOption(commitFilesOperation.operationLabel, commitFilesOperation.operationLabel));
        selectedOperation = commitFilesOperation;
        possibleRunningJobs = '';
        requestGitOperationsFile();
        if(String.isBlank(possibleRunningJobs)){
            possibleRunningJobs = ',GitDeletion,,true;,MetadataDependenciesJob,,true;,GitCommit,,true;,MetadataRetriever,,true';
            if(!String.isBlank(snapshotId) && !String.isBlank(orgId)) {
                possibleRunningJobs = ',GitDeletion,,true;,MetadataDependenciesJob,,true;,GitCommit,' + snapshotId + ',true;,MetadataRetriever,' + orgId +',true';
            }
        }

        snapshotCommitWrappers = new List<SnapshotCommitWrapper>();
        if (Feature__c.getValues('Vlocity') != null) {
            showVlocity = Feature__c.getValues('Vlocity').Enabled__c;
        }
        else {
            showVlocity = false;
        }
    }
    /**
     * Method to get the Base Branch from the CBM Flow, User Story or Release
     */
    public void getBaseBranch() {
        if(userStory != null) {
            List<User_Story__c> userStories = new List<User_Story__c>();
            for(User_Story__c us : [SELECT Id, Base_Branch__c, Release__r.Base_Branch__c FROM User_Story__c WHERE Id = :userStory.Id LIMIT 1]) {
                userStories.add(us);
            }

            if(userStories.size() > 0) {
                GlobalUtilities.deploymentFlowDetails flowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStories[0].Id, '');
                if(flowDetails.isCBMFlow) {
                    // Get Main Branch of Deployment Flow
                    baseBranch = flowDetails.flow.Main_Branch__c != null ? flowDetails.flow.Main_Branch__c : '';
                    System.debug('### userStory Base Branch: ' + userStories[0].Base_Branch__c + ', release Base Branch: ' + userStories[0].Release__r.Base_Branch__c);
                    if (String.isNotEmpty(userStories[0].Base_Branch__c)) {
                        baseBranch = userStories[0].Base_Branch__c;
                    } else if (String.isNotEmpty(userStories[0].Release__r.Base_Branch__c)) {
                        baseBranch = userStories[0].Release__r.Base_Branch__c;
                    }
                    System.debug('### baseBranch: ' + baseBranch);
                }
            }

            if(String.isNotEmpty(baseBranch)) {
                showBaseBranch = true;
            }
        }
    }
    /**
     * Method to switch the selected Operation triggered by a SelectList in the Visualforce page
     */
    public void changeOperation() {
        System.debug('### selectOperation: '+gitCommit.Git_Operation__c);
        Operation newOperation = operationsMap.get(gitCommit.Git_Operation__c);
        if(newOperation != null) {
            selectedOperation = newOperation;
            gitCommit.Git_Operation__c = selectedOperation.operationLabel;

            if(selectedOperation.showUserStorySelections == true) {
                List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :userStoryId AND Name = 'Git Metadata' LIMIT 1];
                if (attachments.size() > 0 && attachments[0].Id != null) {
                    gitMetadataAttachmentId = attachments[0].Id;
                }
                System.debug('gitMetadataAttachmentId: '+gitMetadataAttachmentId);
            } else {
                gitMetadataAttachmentId = '';
            }

            // Get SnapshotCommits if showTable is enabled
            if(selectedOperation.showTable != null && selectedOperation.showTable && selectedOperation.tableSObject != null && selectedOperation.tableSObject == 'USER_STORY_COMMIT__c') {
                getSnapshotCommitWrappers();
            } else {
                snapshotCommitWrappers = new List<SnapshotCommitWrapper>();
            }
        } else {
            selectedOperation = null;
        }
    }
    /**
     * Calls backend for Git Operations file which contains options JSON file
     * @return PageReference
     */
    public PageReference requestGitOperationsFile() {
        try {
            String callUrul = Settings.Server_URL + '/json/v1/gitOperations';
            HttpRequest req = new HttpRequest();
            req.setTimeout(30000);
            DeployAPI.setAuthHeaders(req);
            req.setHeader('Accept', 'application/json');
            req.setEndpoint(callUrul);
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = h.send(req);
            String body = res.getBody();
            system.debug(body);
            parseGitOperationsFile(body);

        } catch (Exception e) {
            catchException(e);
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, LABEL.Connection_Problem));
        }
        return null;
    }
    /**
     * Parser method for Git Operations file retrieved from backend
     * @param jsonStr Backend call Http response body
     */
    private void parseGitOperationsFile(String jsonStr) {

        List<Object> jsonObject = (List<Object>)JSON.deserializeUntyped(jsonStr);

        for (Object o : jsonObject) {
            Operation op = (Operation)JSON.deserialize(JSON.serialize(o), Operation.class);
            // Validate that the operation is available for the current page
            if((userStoryId != null && !op.pages.contains('UserStoryCommit')) || (userStoryId == null && !op.pages.contains('GitSnapshotCommit'))) {
                continue;
            }
            
            if (!String.isEmpty(op.operationLabel)) {
                operationTypes.add(new SelectOption(op.operationLabel, op.operationLabel));
                operationsMap.put(op.operationLabel, op);
            }
            if (!String.isEmpty(op.possibleRunningJob)) {
                if(op.possibleRunningJob.contains(',')) {
                    possibleRunningJobs += op.possibleRunningJob +';';
                }else{
                    // NR: remove this hardcoded code for v12 or so. The GitOperations json now supports the full signature.
                    if (op.operationType == 'VlocityDependencies') {
                        possibleRunningJobs += ',' + op.possibleRunningJob + ','+userStoryId+',true;';
                    } else if(op.operationType == 'MetadataRefresh') {
                        possibleRunningJobs += ',' + op.possibleRunningJob + ',' + orgId + ',true;';
                    } else {
                        possibleRunningJobs += ',' + op.possibleRunningJob + ',' + snapshotId + ',true;';
                    }
                }
            }
        }

        possibleRunningJobs = possibleRunningJobs.replace('{!userStoryId}', userStoryId!=null?userStoryId:'')
                .replace('{!orgId}', orgId!=null?orgId:'')
                .replace('{!snapshotId}', snapshotId!=null?snapshotId:'')
                ;
        System.debug('### possibleRunningJobs: '+possibleRunningJobs);
        System.debug('### OperationsMap: '+operationsMap);
        jsonObject.clear();
    }
    /**
     * Wrapper object to parse Git Operations file easily
     */
    public class Operation {
        public String operationType {get; set;}
        public String operationLabel {get; set;}
        public String operationButtonLabel {get;set;}
        public String endpoint {get;set;}
        public Boolean showCommitMessage {get;set;}
        public String helpText {get;set;}
        public String helpLink {get;set;}
        public List<OperationFormElement> operationFormElements {get;set;}
        public String pages {get;set;}
        public String attachmentName {get;set;}
        public Boolean showAdvancedSection {get;set;}

        // Grid
        public Boolean showGrid {get;set;}
        public Boolean editGrid {get;set;}
        public Boolean reloadGridData {get;set;}
        public String gridMetadataTypes {get;set;}
        public Boolean showUserStorySelections {get;set;}

        // Table
        public Boolean showTable {get;set;}
        public String tableSObject {get;set;}

        public String possibleRunningJob {get;set;}
    }
    /**
     * Wrapper object to parse Git Operation file easily
     */
    public class OperationFormElement {
        public String label {get; set;}
        public String name {get; set;}
        public String type {get; set;}
        public String helpText {get; set;}
        public String value {get;set;}
        public Boolean boolValue {get;set;}
    }
    /**
     * Method to get the list of params from the operation form elements
     */
    public String getOperationFormElementParams() {
        String formElementParams = '';
        if(selectedOperation.operationFormElements != null) {
            for(OperationFormElement element : selectedOperation.operationFormElements) {
                System.debug('### formElement: '+ element);
                if(element.type == 'checkbox') {
                    if(element.boolValue != null) {
                        formElementParams += '&' + EncodingUtil.urlEncode(element.name, 'UTF-8') + '=' + element.boolValue;
                    } else {
                        formElementParams += '&' + EncodingUtil.urlEncode(element.name, 'UTF-8') + '=false';
                    }
                } else if(element.value != null) {
                    formElementParams += '&' + EncodingUtil.urlEncode(element.name, 'UTF-8') + '=' + EncodingUtil.urlEncode(element.value, 'UTF-8');
                }
            }
        }
        System.debug('### formElementParams: '+ formElementParams);
        return formElementParams;
    }
    /**
     * Wrapper object for the Commit Table
     */
    public class SnapshotCommitWrapper {
        public Boolean selected {get; set;}
        public Git_Org_Commit__c snapshotCommit {get; set;}
        public SnapshotCommitWrapper(boolean b, Git_Org_Commit__c snapshotCommit) {
            this.selected = b;
            this.snapshotCommit = snapshotCommit;
        }
    }
    /**
     * Method to retrieve the Snapshot Commits for the Commit Table whenever the User chooses to Undo Commits
     */
    public void getSnapshotCommitWrappers() {
        Integer limitHeapSize = Limits.getLimitHeapSize();
        Integer maxMetadataHeapSize = 0;
        Integer limitCPUTime = Limits.getLimitCpuTime();
        Integer maxCPUTime = 0;

        if (userStoryId != null && Schema.SObjectType.Git_Org_Commit__c.isAccessible()) {
            try {
                for (Git_Org_Commit__c snapshotCommit : [SELECT Name, Commit_Message__c, Status__c, CreatedDate, Git_Operation__c, Commit_Id__c
                FROM Git_Org_Commit__c
                WHERE Id IN (SELECT Snapshot_Commit__c FROM User_Story_Commit__c WHERE User_Story__c = :userStoryId) AND Status__c = 'Complete'
                ORDER BY CreatedDate DESC LIMIT 1000]) {
                    Integer startingHeap = Limits.getHeapSize();
                    Integer startingCpuTime = Limits.getCpuTime();
                    if ((startingHeap + maxMetadataHeapSize * 2) > limitHeapSize || (startingCpuTime + maxCPUTime * 2) > limitCPUTime) {
                        System.debug('### Heap Size limit reached. Exit Git Org Commit for loop.');
                        break;
                    }
                    snapshotCommitWrappers.add(new SnapshotCommitWrapper(false, snapshotCommit));

                    Integer addedHeap = Limits.getHeapSize() - startingHeap;
                    Integer addedCpuTime = Limits.getCpuTime() - startingCpuTime;
                    if (addedHeap > maxMetadataHeapSize) {
                        maxMetadataHeapSize = addedHeap;
                    }
                    if (addedCpuTime > maxCPUTime) {
                        maxCPUTime = addedCpuTime;
                    }
                }
            } catch (Exception e) {
                catchException(e);
            }
        } else if(userStoryId == null && snapshotId != null && Schema.SObjectType.Git_Org_Commit__c.isAccessible()) {
            for (Git_Org_Commit__c snapshotCommit : [SELECT Name, Commit_Message__c, Status__c, CreatedDate, Git_Operation__c, Commit_Id__c
            FROM Git_Org_Commit__c
            WHERE Git_Backup__c = :snapshotId AND Status__c = 'Complete'
            ORDER BY CreatedDate DESC LIMIT 1000]) {
                Integer startingHeap = Limits.getHeapSize();
                Integer startingCpuTime = Limits.getCpuTime();
                if ((startingHeap + maxMetadataHeapSize * 2) > limitHeapSize || (startingCpuTime + maxCPUTime * 2) > limitCPUTime) {
                    System.debug('### Heap Size limit reached. Exit Git Org Commit for loop.');
                    break;
                }
                snapshotCommitWrappers.add(new SnapshotCommitWrapper(false, snapshotCommit));

                Integer addedHeap = Limits.getHeapSize() - startingHeap;
                Integer addedCpuTime = Limits.getCpuTime() - startingCpuTime;
                if (addedHeap > maxMetadataHeapSize) {
                    maxMetadataHeapSize = addedHeap;
                }
                if (addedCpuTime > maxCPUTime) {
                    maxCPUTime = addedCpuTime;
                }
            }
        }
        System.debug('snapshotCommits size: ' + snapshotCommitWrappers.size());
    }
    /**
     * Method to get the list of the selected Commit Ids as a JSON String
     */
    public String getSelectedTableValues() {
        String selectedValues = '';
        List<String> selectedSnapshotIds = new List<String>();
        for (SnapshotCommitWrapper scw : snapshotCommitWrappers) {
            if (scw.selected && scw.snapshotCommit.Id != null) {
                selectedSnapshotIds.add(scw.snapshotCommit.Id);
            }
        }
        if(selectedSnapshotIds.size() > 0) {
            selectedValues = JSON.serialize(selectedSnapshotIds);
        }
        System.debug('### Selected table values: '+selectedValues);
        return selectedValues;
    }

    /**
     * Method to call the GlobalUtilities method that updates the User Story Base Branch field.
     */
    public PageReference updateUserStory() {
        if(userStory != null) {
            GlobalUtilities.updateUserStoryBaseBranch(userStory.Id, baseBranch);
        }
        return null;
    }

    private void catchException(exception e){
        if (ApexPages.currentPage() != null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        errorDetails = e.getStackTraceString();
        system.debug(logginglevel.ERROR, e.getMessage());
        system.debug(logginglevel.ERROR, errorDetails);
    }

}