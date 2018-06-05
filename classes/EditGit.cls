public with sharing class EditGit {

    public Git_Repository__c git {get; set;}
    public String dumypass {get; set;}
    public Boolean keyVisible {get; set;}
    public Boolean isSSHauthentication {get; set;}
    public Boolean hasKeys {get; set;}
    public List<Attachment> attachments {get; set;}
    public String selectedKeyId {get; set;}
    public String selectedKeyContent {get; set;}
    public final String KEYNAME = 'id_rsa.pub';
    public List<GitHelper.ACommit> commits;
    public boolean showOtherInformation {get; set;}
    public boolean isShareable {get; set;}
    public List<Git_Backup__c> snapshots {get; set;}
    public Boolean showError {get;set;} 
    public Boolean showOptions {get;set;}
    public id currentId;

    public EditGit(ApexPages.StandardController std) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) std.addFields(new List<String>(Schema.SObjectType.Git_Repository__c.fields.getMap().keySet()));

        showOptions = true;
        showError = false;
        isLicenseEnabled();
        showOtherInformation = SObjectType.Git_Repository__c.FieldSets.CustomFields.getFields().size() > 0;
        keyVisible = false;
        hasKeys = false;
        isSSHauthentication = false;
        selectedKeyContent = '';
        dumypass = '********';
        if (std.getId() != null) {
            git = utilities.getGitById(std.getId());
            currentId = git.id;
            if (!git.URI__c.startsWith('https')) {
                dumypass = '';
                isSSHauthentication = true;
                getKeys();
            }
            getRelated();
        } else {
            git = new Git_Repository__c();
        }

        Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
        isShareable = tokens.containsKey('Git_Repository__Share');
    }
    public void getRelated() {
        snapshots = ExternalCIAPIFactory.queryAllValues('Git_Backup__c', 'Git_Repository__c', git.Id, '', '');
    }
    public PageReference save() {
        if(null != currentId && !Utilities.HasEditAccess(currentId)){
            git.addError(Label.InSuffPriv);
            return null;
        }
        Utilities.Secure_DML(git, Utilities.DML_Action.UPS, schema.Sobjecttype.Git_Repository__c);
        return new apexpages.standardController(git).view();
    }
    public PageReference validate(){
        DeployAPI.validateGitResult validation = DeployAPI.validateGit(git.Id);
        if(validation.success) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, validation.message));
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, validation.message));
        }
        //check features sync and sync if necessary.
        if(Test.isRunningTest())return null;
        return null;
    }
    public void viewKey() {
        if (!String.isBlank(selectedKeyId)) {
            List<Attachment> tmp = [select Body from Attachment where Id = :selectedKeyId limit 1];
            if (tmp.size() > 0) {
                selectedKeyContent = tmp.get(0).Body.toString();
                keyVisible = true;
                selectedKeyId = '';
                return;
            }
        }
    }
    public PageReference deleteKey() {
        try {
            Utilities.Secure_DML([select Id from Attachment where Id = :selectedKeyId limit 1], Utilities.DML_Action.DEL, schema.Sobjecttype.Attachment);
            return new PageReference('/' + git.Id);
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            return null;
        }
    }
    public PageReference hideSSHkey() {
        return new PageReference('/' + git.Id);
    }
    private void getKeys() {
        attachments = new List<Attachment>();
        attachments = [select Id, Name, Body, ParentId, CreatedDate, LastModifiedDate from Attachment where Name = :KEYNAME and ParentId = :git.Id];
        if (attachments.size() == 1) {
            hasKeys = true;
        } else {
            hasKeys = false;
        }
    }
    public PageReference createSSHKey() {
        try {
            String result = DeployAPI.createSSHKey(git.Id);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, result));
            return new PageReference('/' + git.Id);
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            return null;
        }
    }
    public List<GitHelper.ACommit> getCommits() {
        DateTime frm = DateTime.now().addYears(-1);
        return GitHelper.getCommits(git.Id, null, frm.date(), Date.today() + 1, null, null, 10);
    }
    public PageReference deployCommits() {
        PageReference pr = Page.DeployCommits;
        pr.getParameters().put('repositoryId', git.Id);
        return pr;
    }

    public void retrieveCommits() {
        String branch = Apexpages.currentPage().getParameters().get('branch');
        System.debug('branch: ' + branch);
        try {
            DeployAPI.getCommitsFromRepo(git.Id, branch);
            ApexPages.getMessages().clear();
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.info, Label.COMMITS_BEING_RETRIEVED ));
        } catch (Exception e) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.error, e.getMessage()));
        }
        // return null;
    }
    public void isLicenseEnabled(){
        if (!LicenseHelper.actionIsLicenseEnabled('viewEditGitRepository')){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CAD_License_Restriction));
            showError = true;
            showOptions = false;
        }
        return;
    }

    public PageReference goToManageGITBranches(){
        PageReference pr = Page.ManageGitBranches;
        pr.getParameters().put('repoId',git.Id);
        pr.setRedirect(true);
        return pr;
    }

}