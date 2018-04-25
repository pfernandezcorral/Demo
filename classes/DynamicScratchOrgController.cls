/**
 * Created by mertyalti on 01/02/2018.
 */

public with sharing class DynamicScratchOrgController extends ScratchOrgWizardPageBase {
    public Test_Run__c testRun {get;set;}
    private Id stdObjectId;
    private String sourceBranch;
    public String initialPageMessage {get;set;}
    public Boolean showInitialPageMessage {get;set;}
    public Boolean showComponent {get;set;} //only allowed for Scratch Org Related User Stories
    public DynamicScratchOrgController(ApexPages.StandardController std) {
        showComponent = true;
        showInitialPageMessage = true;
        stdObjectId = std.getId();
        Schema.sObjectType parentObject = stdObjectId.getSObjectType();

        if (parentObject == Schema.SObjectType.Test_Run__c.getSobjectType()) {
            testRunOperation();
        } else if (parentObject == Schema.SObjectType.Promotion__c.getSobjectType()) {

        } else {
            // TODO: page is not supported.
        }
    }
    private void testRunOperation(){
        testRun = [SELECT Id, Name, Test_Script__r.User_Story__r.Org_Credential__r.Org_Type__c , Test_Script__r.User_Story__r.Org_Credential__r.Developer_Hub_Org__c, Test_Script__r.User_Story__r.Org_Credential__c,Test_Script__r.User_Story__r.Name FROM Test_Run__c WHERE Id = :stdObjectId LIMIT 1];
        if (testRun.Test_Script__c != null && testRun.Test_Script__r.User_Story__c != null && testRun.Test_Script__r.User_Story__r.Org_Credential__c != null && testRun.Test_Script__r.User_Story__r.Org_Credential__r.Org_Type__c == 'Scratch Org' && testRun.Test_Script__r.User_Story__r.Org_Credential__r.Developer_Hub_Org__c != null) {
            Id orgId = testRun.Test_Script__r.User_Story__r.Org_Credential__c;
            Org__c usOrg = [SELECT Id,Org_Type__c,Scratch_Org_Expiration_Date__c,Scratch_Org_Status__c,Developer_Hub_Org__c FROM Org__c WHERE Id=:orgId];
            wizardDevHubId = usOrg.Developer_Hub_Org__c;
            sourceBranch = SfdxAPIHelper.DX_PROJECT_BRANCH+String.valueOf(testRun.Test_Script__r.User_Story__r.Org_Credential__c).substring(3,15);
            initialPageMessage = 'Test Scratch org will be created out of '+sourceBranch;
            try {
                Attachment attDefinition = getOrgAttachment(orgId,SfdxAPIHelper.DX_DEFINITION_FILE);
                Attachment attProject = getOrgAttachment(orgId,SfdxAPIHelper.DX_PROJECT_FILE);
                orgTemplate = (SfdxAPIHelper.ScratchOrgDefinition) JSON.deserialize(attDefinition.Body.toString(), SfdxAPIHelper.ScratchOrgDefinition.class);
                orgTemplate.orgName = testRun.Name+' Scratch Org';
                orgTemplate.username = '';
                artifactProject = (SfdxAPIHelper.sfdxProject) JSON.deserialize(attProject.Body.toString(), SfdxAPIHelper.sfdxProject.class);
            } catch(Exception ex) {
            	System.debug(loggingLevel.Error,'*** ERROR : '+ex.getMessage()); // TODO: Add page message
            }

        } else {
            showComponent = false;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No org credentials found or missing configuration.'));
        }
    }

    private Attachment getOrgAttachment(Id ParentId, String attName){
        return [SELECT Id,Body,ParentId,Name FROM Attachment WHERE ParentId =:ParentId AND Name =: attName];
    }

    public PageReference loadReviewData() {
        if(orgTemplate != null && artifactProject != null){
            ScratchOrgCompletionController completionController = ((ScratchOrgCompletionController) getComponentController('ScratchOrgCompletion'));
            completionController.orgDefinition = orgTemplate;
            completionController.artifactProject = artifactProject;
            completionController.artifactDirectories = new List<SfdxAPIHelper.sfdxProjectArtifacts>();
            for (SfdxAPIHelper.sfdxProjectArtifacts art : artifactProject.packageDirectories) {
                Boolean defaultArtifact = art.defaultArtifact != null ? art.defaultArtifact : art.path == 'force-app' ? true : false;
                completionController.artifactDirectories.add(new SfdxAPIHelper.sfdxProjectArtifacts(art.path,defaultArtifact));
            }
            completionController.parentId = stdObjectId;
            completionController.devHubOrgId = wizardDevHubId;
            completionController.showPermissionsPanel = false;
            completionController.sourceBranch = sourceBranch;
            completionController.showSetup = false;
        }
        return null;
    }

    public PageReference jobStatusNotification() {
        Boolean jobFinished = ApexPages.currentPage().getParameters().get('jobFinished') == 'true' ? true : false;
        Boolean jobSuccess = ApexPages.currentPage().getParameters().get('jobSuccess') == 'true' ? true : false;
        String jobMessage = ApexPages.currentPage().getParameters().get('jobMessage');
        String jobType = ApexPages.currentPage().getParameters().get('jobType');

        if (jobFinished && jobSuccess && String.isNotBlank(jobType)) {
            if (jobType == CopadoNotificationHelper.DX_CREATE_FULL_ORG) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Scratch_Org_Created_Success));
                PageReference pRef = Page.DXTestOrgIntermediary;
                pRef.getParameters().put('id',testRun.Id);
                pRef.setRedirect(true);
                return pRef;
            }
        } else if (jobFinished && !jobSuccess && String.isNotBlank(jobMessage)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, jobMessage));
        }
        return null;
    }

}