public with sharing class UserStoryCommitIntermediaryExt {
    public User_Story__c userStory {get;set;}
    public ApexPages.Standardcontroller controller {get;set;}
    
    public List<Git_Backup__c> snapshots {get;set;}
    public Boolean showOptions {get;set;}
    public Boolean showError {get;set;}
    public Boolean showCreateDXBranchButton {get;set;}
    public String snapshotId {get;set;}
    public String repoId {get;set;}
    public String orgId {get;set;}
    public String targetPage{get;set;}
    public GlobalUtilities.deploymentFlowDetails flowDetails {get;set;}

    public String mainBranch {get;set;}
    
    public static final String[] FIELDS = new String[] {'Id','Name','Org_Credential__c', 'Environment__c', 'Org_Credential__r.Environment__c','Org_Credential__r.Org_Type__c', 'Base_Branch__c', 'Release__r.Base_Branch__c','Project__r.Deployment_Flow__r.Git_Repository__c','Release__r.Project__r.Deployment_Flow__r.Git_Repository__c'};
    
    public UserStoryCommitIntermediaryExt(ApexPages.StandardController stdController) {
        snapshotId = '';
        mainBranch = '';
        showOptions = false;
        showError = false;
        showCreateDXBranchButton = false;
        controller = stdController;
        targetPage = ApexPages.currentPage().getParameters().get('targetPage')!=null?ApexPages.currentPage().getParameters().get('targetPage'):'GitCommitChanges';
        if (!Test.isRunningTest()) {
            stdController.addFields(FIELDS);
        }
        this.userStory = (User_Story__c)stdController.getRecord();
        if(this.userStory==null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.USER_STORY_COMMIT_NO_USER_STORY));
        } else {
            getOptions();
        }
    }
    public void getOptions(){ 
        snapshots = new List<Git_Backup__c>();

        if(LicenseHelper.isLicensesExceeded()) {           
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.LICENSES_EXCEEDED));
            showError = true;
            showOptions = false;//Defult false
            return;
        }

        if(!LicenseHelper.actionIsLicenseEnabled('commitFiles')){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CAD_License_Restriction));
            showError = true;
            showOptions = false;//Defult false
            return;
        }
        if(!FeatureHelper.isChangeChangeManagementEnabled()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.FEATURE_NOT_SUPPORTED));
            showError = true;
            showOptions = false;//Defult false
            return;
        }

        flowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        System.debug('flowDetails: '+flowDetails);
        if(flowDetails.isCBMFlow) {

            // Get Main Branch of Deployment Flow
            mainBranch = flowDetails.flow.Main_Branch__c != null ? flowDetails.flow.Main_Branch__c : '';
            System.debug('### userStory Base Branch: '+userStory.Base_Branch__c);
            System.debug('### release Base Branch: '+userStory.Release__r.Base_Branch__c);
            if(String.isNotEmpty(userStory.Base_Branch__c)) {
                mainBranch = userStory.Base_Branch__c;
            } else if(String.isNotEmpty(userStory.Release__r.Base_Branch__c)) {
                mainBranch = userStory.Release__r.Base_Branch__c;
            }
            System.debug('### mainBranch: '+mainBranch);

            if(!Schema.SObjectType.Deployment_Flow__c.fields.Git_Repository__c.isAccessible() ||
                !Schema.SObjectType.Deployment_Flow__c.fields.Main_Branch__c.isAccessible() ||
                !Schema.SObjectType.Deployment_Flow_Step__c.fields.Branch__c.isAccessible() ||
                !Schema.SObjectType.Deployment_Flow_Step__c.fields.Source_Environment__c.isAccessible() ||
                !Schema.SObjectType.Deployment_Flow_Step__c.fields.Destination_Environment__c.isAccessible() ||
                !Schema.SObjectType.Git_Repository__c.fields.Name.isAccessible() ||
                !Schema.SObjectType.Git_Repository__c.fields.URI__c.isAccessible() ||
                !Schema.SObjectType.Git_Repository__c.fields.Username__c.isAccessible() ||
                !Schema.SObjectType.Git_Repository__c.fields.Password__c.isAccessible() ||
                !Schema.SObjectType.Git_Backup__c.fields.Org__c.isAccessible() ||
                !Schema.SObjectType.Git_Backup__c.fields.Git_Repository__c.isAccessible() ||
                !Schema.SObjectType.Git_Backup__c.fields.Frequency__c.isAccessible() ||
                !Schema.SObjectType.Git_Backup__c.fields.Git_Snapshot_Permissions__c.isAccessible() ||
                !Schema.SObjectType.Git_Backup__c.fields.Branch__c.isAccessible()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MISSING_PERMISSIONS_CBM_FLOW));
                showError = true;
                showOptions = false;
                return;
            }
        }

        // Check if Flow is Active
        if(flowDetails.flow == null || !flowDetails.flow.Active__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.PROMOTION_FLOW_INACTIVE));
            showError = true;
            showOptions = false;
            return;
        }

        // Check if Commits are allowed
        if(flowDetails.flow != null && flowDetails.flow.Block_Commits__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.DEPLOYMENT_FLOW_COMMITS_BLOCKED));
            showError = true;
            showOptions = false;
            return;
        }

        if(String.isBlank(userStory.Environment__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.USER_STORY_COMMIT_NO_ENVIRONMENT));
            showError = true;
            showOptions = false;
            return;
        }
       
       snapshots = [select Id, Name, Org__c, Git_Repository__c, Git_Repository__r.Name, Org__r.Name, Org__r.OwnerId, Org__r.Environment__c, Branch__c, Frequency__c, Git_Snapshot_Permissions__c from Git_Backup__c where (Git_Snapshot_Permissions__c='' or Git_Snapshot_Permissions__c!='Allow Snapshots Only') and Org__r.Environment__c=:userStory.Environment__c limit 100];
       if(userStory != null && snapshots.size()==0 && userStory.Org_Credential__r.Org_Type__c == 'Scratch Org'){
            //If no snapshot and it's Scratch Org, we look for the attachmet to see if scratch org was created from ArtifactUMP if so, we allow users to create it
            List<Attachment> attList = [SELECT Body FROM Attachment WHERE ParentId =: userStory.Org_Credential__c AND  Name = : SfdxAPIHelper.DX_METADATA_SOURCES LIMIT 1];
            if(attList.size()>0){
                Map<String, Object> deserializedJsonMap = (Map<String, Object>) JSON.deserializeUntyped(attList.get(0).Body.toString());
                String mSourceType = deserializedJsonMap.containsKey('metadataSourceType') ? String.ValueOf(deserializedJsonMap.get('metadataSourceType')) : '';
                String mSource = deserializedJsonMap.containsKey('metadataSource') ? String.ValueOf(deserializedJsonMap.get('metadataSource')) : '';
                //String pBranchCreated = deserializedJsonMap.containsKey('projectBranchCreated') ? String.ValueOf(deserializedJsonMap.get('projectBranchCreated')) : '';
                if (String.isNotBlank(mSource) &&  String.isNotBlank(mSourceType)  /*&&  String.isNotBlank(pBranchCreated) && pBranchCreated != 'true'  */&& mSourceType == 'artifactUMP') {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'DX Project has not been created would you like to create it?'));
                    showCreateDXBranchButton = true;
                    showError = true;
                    showOptions = false;
                    return;
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND));
                    showError = true;
                    showOptions = false;
                    return;
                }
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND));
                showError = true;
                showOptions = false;
                return;
            }
        }else if(snapshots.size()==0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND));
            showError = true;
            showOptions = false;
            return;
        }

        if(snapshots.size()==1){
            showError = false;
            showOptions = false;
            snapshotId = snapshots[0].Id;
            orgId = snapshots[0].Org__c;
            repoId = snapshots[0].Git_Repository__c;
            return;
        }
        if(snapshots.size()>1){
            showError = false;
            showOptions = true;
            return;
        }
    }
    
    //FL: manually fix Copado-auto-merge where 402 code wons over 438
    public String getAdditionalParams() {
        PageReference pr = new PageReference('/');
        for(String k : ApexPages.currentPage().getParameters().keySet()) {
            pr.getParameters().put(k, ApexPages.currentPage().getParameters().get(k));
        }
        pr.getParameters().remove('id');
        String pr1 = pr.getUrl().replace('/?', '').replace('/%3f', '').replace('/%3F', '');
        System.debug('pr1='+pr1);
        return pr1.length()>0 ? pr1+'&' : '';
    }

    public PageReference createDXBranch(){
        String depFlowGitRepoId = '';
        if (userStory.Project__r.Deployment_Flow__r.Git_Repository__c != null) {
            depFlowGitRepoId = userStory.Project__r.Deployment_Flow__r.Git_Repository__c;
        } else if (userStory.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c != null) {
            depFlowGitRepoId = userStory.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
        }
        SfdxAPI.createProjectBranch(userStory.Org_Credential__c,depFlowGitRepoId);
        return null;
    }

    public PageReference jobStatusNotification() {
        Boolean jobFinished = ApexPages.currentPage().getParameters().get('jobFinished') == 'true' ? true : false;
        Boolean jobSuccess = ApexPages.currentPage().getParameters().get('jobSuccess') == 'true' ? true : false;
        String jobMessage = ApexPages.currentPage().getParameters().get('jobMessage');
        String jobType = ApexPages.currentPage().getParameters().get('jobType');

        if (jobFinished && jobSuccess && String.isNotBlank(jobType)) {
            if (jobType == CopadoNotificationHelper.DX_CREATE_PROJECT_BRANCH) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Scratch_Org_Created_Success));
                PageReference p =  ApexPages.currentPage();
                p.getParameters().clear();
                p.getParameters().put('Id',userStory.Id);
                p.setRedirect(true);
                return p;
            }
        } else if (jobFinished && !jobSuccess && String.isNotBlank(jobMessage)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, jobMessage));
        }
        return null;
    }

}