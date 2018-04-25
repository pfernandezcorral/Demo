public with sharing class ArtifactManageMetadataController {

    private Artifact__c artifact {get;set;}
    public Boolean hasOrg {get;set;}
    public String metadata_url_art {get;set;}
    public Settings settings{get;set;}
    public Boolean showError {get;set;} 
    public Boolean showOptions {get;set;}
    public List<Id> relatedArtifactIds{get;set;}
    public Boolean copadoJobFinished {get;set;}
    public String slockerMessage {get; set;}
    private String cJobId = '';
    private Boolean gitExistAndValid = false;
    public Boolean jobisExecuting  {get;set;}
    public Boolean hasOLS {get;set;}

    public ArtifactManageMetadataController(ApexPages.StandardController stdController) {

        //check OLS for all the Objects needed on this page.
        hasOLS = hasOLSforAll();
        if(!hasOLS){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING,'OLS missing for the related Objects, please make sure you have the right OLS for Artifacts, Org Credentials and Git Repos'));
        }

        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Artifact__c.fields.getMap().keySet()));
        }
        slockerMessage = CopadoNotificationHelper.STATUS_DEFAULT_VALUE;
        settings = new Settings();
        copadoJobFinished = false;
        hasOrg = false;
        showOptions = true;
        showError = false;
        this.artifact = (Artifact__c)stdController.getRecord();
        //gitExistAndValid = Artifact__c.Artifact_Repository__c != null && DeployAPI.validateGit(this.artifact.Artifact_Repository__c).success;
        gitExistAndValid = String.isNotBlank(this.artifact.Artifact_Repository__c) ? DeployAPI.validateGit(this.artifact.Artifact_Repository__c).success : false;
        if(this.artifact.Org_Credential__c!=null){
            Org__c org = utilities.getOrgById(artifact.Org_Credential__c);
            hasOrg=true;
            String urlParameters = '';
            String herokuServer = settings.herokuServer;
            String urlBase = herokuServer + '/json/v1/'; 
            metadata_url_art = urlBase + 'metadata/'+EncodingUtil.urlEncode(artifact.Org_Credential__c,'UTF-8') + urlParameters + '?dates=format&parentId='+EncodingUtil.urlEncode(artifact.Org_Credential__c,'UTF-8');
            relatedArtifactIds = new List<Id>();
            for(Artifact__c a : [SELECT Id FROM Artifact__c WHERE Org_Credential__c =: artifact.Org_Credential__c AND Id != : artifact.Id]){
                relatedArtifactIds.add(a.Id);
            }
            Copado_Notification__c cn = CopadoNotificationHelper.qInProgressCopadoNotification(CopadoNotificationHelper.DX_ARTIFACT_GIT_SNAPSHOT,artifact.Id);
            if(cn != null){
                cJobId = cn.Matching_Key__c;
                slockerMessage = cn.status__c;
                jobisExecuting = true;
            }

        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No Org Credential on Artifact'));
        }
    }

    private Boolean hasOLSforAll(){
        List<Schema.DescribeSObjectResult> dsrList = new List<Schema.DescribeSObjectResult>();

        dsrList.add(Schema.SObjectType.Artifact__c);
        dsrList.add(Schema.SObjectType.Org__c);
        dsrList.add(Schema.SObjectType.Git_Repository__c);

        Map<Schema.DescribeSObjectResult,SfdxAPIHelper.ObjectLevelSecurity> olsMap = SfdxAPIHelper.checkOLS(dsrList);

        if(olsMap.get(Schema.SObjectType.Artifact__c).accessible &&
            olsMap.get(Schema.SObjectType.Artifact__c).updateable &&
            olsMap.get(Schema.SObjectType.Org__c).accessible &&
            olsMap.get(Schema.SObjectType.Git_Repository__c).accessible){
            return true;
        }else{
            return false;
        }
    }

    public PageReference callJob(){
        //gitExistAndValid = Artifact__c.Artifact_Repository__c != null && DeployAPI.validateGit(this.artifact.Artifact_Repository__c).success;
        gitExistAndValid = String.isNotBlank(this.artifact.Artifact_Repository__c) ? DeployAPI.validateGit(this.artifact.Artifact_Repository__c).success : false;
        copadoJobFinished = false;
        cJobId = '';
        return checkJobApex();
    }

    public PageReference checkJobApex(){
        PageReference pr = null;
        try{
            //If no git repo or not validated git repo return and show warning
            if(!gitExistAndValid){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING,'Git repo is not set or not valid, please review to be able to upload to Git'));
                copadoJobFinished = true;
                return null;
            }

            if(cJobId == '' && artifact.Id != null){
                String s = SfdxAPI.artifactSnapshot(artifact.Id);
                CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(s,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
                if(r.copadoJobId != null && r.copadoJobId != ''){
                    cJobId = r.copadoJobId;
                    slockerMessage = r.ok;
                    Copado_Notification__c newCN = CopadoNotificationHelper.instCopadoNotification(CopadoNotificationHelper.PROGRESS_STATUS_COPADO, artifact.Id,CopadoNotificationHelper.DX_ARTIFACT_GIT_SNAPSHOT,cJobId);
                    Utilities.Secure_DML(newCN, Utilities.DML_Action.INS, schema.Sobjecttype.Copado_Notification__c);
                    copadoJobFinished = false;
                }else if(r.error != null && r.error != ''){
                    copadoJobFinished = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,r.error));
                }
            }else{
                Copado_Notification__c c = CopadoNotificationHelper.qCopadoNotificationBycopadoJobId(cJobId);
                if(c.isFinished__c != null && c.isFinished__c){
                    //is either success or not
                    if(c.isSuccess__c){
                        copadoJobFinished = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM,'Success'));
                        cJobId = '';
                    }else{
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,c.Message__c != null ? c.Message__c : c.status__c != null ? c.status__c : 'Could not push to repo')); // To Do Add Label
                        copadoJobFinished = true;
                    }
                }else{
                    slockerMessage = c.status__c;
                    copadoJobFinished = false;
                }

            }
        }catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage()));
            copadoJobFinished = true;
        }
        return pr;
    }
    /**
     * Method to be called from JS or Apex and show a fixed message includes two parameters (errorLevel and messageName)
     */
    public String errorLevel {get; set;}
    public String messageName {get; set;}
    public void showMessage() {
        ApexPages.Severity level = ApexPages.Severity.ERROR;
        if(errorLevel == 'WARNING') {
            level = ApexPages.Severity.Warning;
        }else{
            if(errorLevel == 'CONFIRM') {
                level = ApexPages.Severity.CONFIRM;
            }
        }
        ApexPages.addMessage(new ApexPages.Message(level, messageName));
    }
}