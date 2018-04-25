public with sharing class CreateUserStoryScratchOrgController extends ScratchOrgWizardPageBase {
    public User_Story__c parentUS { get; set; }
    public ScratchOrgWizardComponentBase componentController { get; set; }
    public String definition { get; set; }
    public String metadata { get; set; }
    public String review { get; set; }
    public String nextButtonLabel { get; set; }
    public Boolean disableNextButton { get; set; }
    public Boolean disablePreviousButton { get; set; }
    public Boolean showSaveDefinition { get; set; }
    public Boolean showSaveProjectTemplate { get; set; }
    public Boolean isDXEnabled { get; set; }
    public String selectedPermissions { get; set; }
    public Boolean jobFinished {get;set;}
    public String dxDeploymentFlowMode { get; set; }
    private String sourceBranch;

    public CreateUserStoryScratchOrgController(ApexPages.StandardController std) {
        if (!Test.isRunningTest()) { std.addFields(new List<String>(Schema.SObjectType.User_Story__c.fields.getMap().keySet())); }
        parentUS = (User_Story__c) std.getRecord();
        Deployment_Flow__c depFlow = SfdxAPIHelper.usDeploymentFlow(parentUS.Id);
        if(depFlow != null){
            isDXEnabled = SfdxAPIHelper.isDXEnabledForUSDeploymentFlow(depFlow);
            dxDeploymentFlowMode = isDXEnabled ? SfdxAPIHelper.dxModeForUserStory(depFlow) : '';
        } else {
            isDXEnabled = false;
            dxDeploymentFlowMode = '';
        }

        jobFinished = false;
        standardControllerID = parentUS.Id;
        definition = Stage.CURRENT.Name();
        metadata = Stage.INCOMPLETE.Name();
        review = Stage.INCOMPLETE.Name();
        showSaveDefinition = true;
        showSaveProjectTemplate = true;
        nextButtonLabel = 'Next';
        disableNextButton = false;
        disablePreviousButton = true;
        if (!isDXEnabled) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.WARNING, SfdxAPIHelper.flowMessage));
        } else if (parentUS.Org_Credential__c != null) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.WARNING, Label.DX_US_ALREADY_HAS_AN_ORG));
        }
    }

    public override void setComponentController(ScratchOrgWizardComponentBase wizCompController) {
        componentController = (ScratchOrgWizardComponentBase) wizCompController;
    }

    public override ScratchOrgWizardComponentBase getMyComponentController() {
        return componentController;
    }
    public PageReference loadReviewData() {
        ScratchOrgCompletionController completionController = ((ScratchOrgCompletionController) getComponentController('ScratchOrgCompletion'));
        completionController.orgDefinition = orgTemplate;
        completionController.artifactProject = artifactProject;
        System.debug(loggingLevel.INFO, '*** completionController.artifactProject: ' + completionController.artifactProject);
        completionController.parentId = standardControllerID;
        completionController.deploymentFlowOperations();
        return null;
    }
    String currentStage = Stage.CURRENT.Name();
    String completeStage = Stage.COMPLETE.Name();
    String incompleteStage = Stage.INCOMPLETE.Name();
    public PageReference nextStep() {
        disableNextButton = false;
        if (definition == currentStage) {
            ScratchOrgController orgTemplateController = ((ScratchOrgController) getComponentController('ScratchOrgTemplate'));
            Boolean orgDefinitionCompleted = orgTemplateController.validateStep(false);
            if (!orgDefinitionCompleted) return null;
            wizardDevHubId = orgTemplateController.devHubOrgId;
            definition = completeStage;
            orgTemplate = orgTemplateController.orgTemplate;
            orgTemplate.orgName = orgTemplateController.dxUserStoryName;
            metadata = currentStage;
            review = incompleteStage;
            showSaveDefinition = false;
            showSaveProjectTemplate = true;
            nextButtonLabel = 'Next';
            disablePreviousButton = false;
        } else if (metadata == currentStage) {
            ScratchOrgMetadataController metadataController = ((ScratchOrgMetadataController) getComponentController('ScratchOrgMetadata'));
            System.debug(LoggingLevel.INFO, '***typeName :' + metadataController.typeName);
            if (metadataController.typeName != 'artifact' && metadataController.typeName != 'artifactUMP') {
                if (metadataController.typeName == 'branch') {
                    String branchName = ApexPages.currentPage().getParameters().get('nextStepParam');
                    System.debug(loggingLevel.INFO, '*** branchName: ' + branchName);
                    sourceBranch = branchName;
                    metadataController.artifactProject.packageDirectories = new List<SfdxAPIHelper.sfdxProjectArtifacts>{
                            new SfdxAPIHelper.sfdxProjectArtifacts(sourceBranch, true)
                    };
                } else {
                    if (metadataController.typeName == 'patch') {
                        String branchName = ApexPages.currentPage().getParameters().get('nextStepParam');
                        System.debug(loggingLevel.INFO, '*** tagName: ' + branchName + '  ::: ' + metadataController.metadataSources);
                        sourceBranch = branchName;
                        metadataController.metadataSources.isPatch = true;
                        metadataController.metadataSources.metadataSource = branchName;
                        metadataController.sourceSelections = branchName;
                    }
                    metadataController.artifactProject.packageDirectories = new List<SfdxAPIHelper.sfdxProjectArtifacts>{
                            new SfdxAPIHelper.sfdxProjectArtifacts(SfdxAPIHelper.DX_DEFAULT_PATH, true)
                    };
                }
            } else {
                SfdxAPIHelper.metadataSources mdSelections = new SfdxAPIHelper.metadataSources(metadataController.sourceSelections.replace('[', '').replace(']', '').replaceAll('\\s+', ''), metadataController.typeName, '');
                List<SfdxAPIHelper.sfdxProjectArtifacts> artifactDirectories = new List<SfdxAPIHelper.sfdxProjectArtifacts>();
                for (String art : metadataController.sourceSelections.replace('[', '').replace(']', '').split(',')) {
                    if(!art.isWhitespace()) {
                        mdSelections.selectedArtifactIDs.add(art.replaceAll('\\s+', ''));
                    }
                }
                artifactDirectories.add(new SfdxAPIHelper.sfdxProjectArtifacts(SfdxAPIHelper.DX_DEFAULT_PATH, true));
                for (Artifact__c artifacts : [Select Name From Artifact__c Where Id In :mdSelections.selectedArtifactIDs]) {
                    artifactDirectories.add(new SfdxAPIHelper.sfdxProjectArtifacts(artifacts.Name, false));
                }

                metadataController.artifactProject.packageDirectories = artifactDirectories;
                System.debug(LoggingLevel.INFO, '***metadataController.artifactProject :' + metadataController.artifactProject);
            }
            artifactProject = metadataController.artifactProject;
            System.debug(LoggingLevel.INFO, '***artifactProject :' + artifactProject);
            definition = completeStage;
            metadata = completeStage;
            review = currentStage;
            showSaveDefinition = false;
            showSaveProjectTemplate = false;
            disablePreviousButton = false;
            nextButtonLabel = 'Complete Setup';
        } else if (review == currentStage) {
            jobFinished = false;
            System.debug(LoggingLevel.INFO, '***artifactProject complete :' + artifactProject);
            System.debug('**f**artifactProject.packageDirectories : ' + artifactProject.packageDirectories);
            definition = completeStage;
            metadata = completeStage;
            review = completeStage;
            nextButtonLabel = 'Creating Scratch Org';
            disablePreviousButton = true;

            ScratchOrgCompletionController completionController = ((ScratchOrgCompletionController) getComponentController('ScratchOrgCompletion'));
            ScratchOrgMetadataController metadataController = ((ScratchOrgMetadataController) getComponentController('ScratchOrgMetadata'));
            ScratchOrgController templateController = ((ScratchOrgController) getComponentController('ScratchOrgTemplate'));

            String orgTemplateJSON = SfdxAPIHelper.prepareOrgDefinition(orgTemplate);
            String artifactIds, sourceOrgId;
            String typeName = metadataController.typeName;
            String selectedSource = metadataController.sourceSelections;
            System.debug(loggingLevel.INFO, '*** selectedSource: ' + selectedSource);
            if (typeName == 'artifact') {
                artifactIds = String.isNotBlank(selectedSource) ? selectedSource.replace('[', '').replace(']', '') : '';
            } else if (typeName == 'org') {
                sourceOrgId = selectedSource;
            }
            completionController.showPermissionsPanel = false;
            completionController.showDeploymentFlow = false;
            completionController.showSetup = false;
            disableNextButton = true;

            System.debug('**f**orgTemplateJSON : ' + orgTemplateJSON);
            System.debug('**f**artifactIds : ' + artifactIds);
            System.debug('**f**sourceBranch : ' + sourceBranch);
            System.debug('**f**wizardDevHubId : ' + wizardDevHubId);
            System.debug('**f**completionController.selectedPermissions : ' + completionController.selectedPermissions);
            System.debug('**f**selectedPermissions : ' + selectedPermissions);


            metadataController.generateSfdxProjectJson();
            SfdxAPI.fullScratchOrg(orgTemplateJSON, wizardDevHubId, orgTemplate.orgName, ((ScratchOrgController) getComponentController('ScratchOrgTemplate')).duration, completionController.depFlowId, completionController.getFlowDXDestination(), artifactIds, sourceOrgId, sourceBranch, selectedPermissions, metadataController.getProjectJson(), metadataController.getMdSourcesJson(), completionController.depFlowGitRepoId, standardControllerID, metadataController.convertSource);
            completionController.completionMessage = Label.CreateFullScratchOrg_Init_Message;
        }
        return null;
    }

    public PageReference previousStep() {
        disableNextButton = false;
        disablePreviousButton = true;
        if (metadata == currentStage) {
            definition = currentStage;
            metadata = incompleteStage;
            review = incompleteStage;
            showSaveDefinition = false;
            showSaveProjectTemplate = false;
            disablePreviousButton = true;
            nextButtonLabel = 'Next';
        } else if (review == currentStage) {
            definition = completeStage;
            metadata = currentStage;
            review = incompleteStage;
            nextButtonLabel = 'Next';
            disablePreviousButton = false;
        }
        return null;
    }

    public enum Stage {
        CURRENT, INCOMPLETE, COMPLETE
    }

    public PageReference jobStatusNotification() {
        jobFinished = ApexPages.currentPage().getParameters().get('jobFinished') == 'true' ? true : false;
        Boolean jobSuccess = ApexPages.currentPage().getParameters().get('jobSuccess') == 'true' ? true : false;
        String jobMessage = ApexPages.currentPage().getParameters().get('jobMessage');
        String jobType = ApexPages.currentPage().getParameters().get('jobType');

        if (jobFinished && jobSuccess && String.isNotBlank(jobType)) {
            jobFinished = true;
            if (jobType == CopadoNotificationHelper.DX_CREATE_FULL_ORG) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Scratch_Org_Created_Success));
            } else if (jobType == CopadoNotificationHelper.DX_LIST_REPO_BRANCHES) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, 'Branches retrieved successfully'));
            }
        } else if (jobFinished && !jobSuccess && String.isNotBlank(jobMessage)) {
            jobFinished = true;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, jobMessage));
        }
        return null;
    }
}