/**
 * Created by mertyalti on 15/01/2018.
 */

public with sharing class ScratchOrgCompletionController extends ScratchOrgWizardComponentBase {
    public SfdxAPIHelper.sfdxProject artifactProject { get; set; }
    public List<SfdxAPIHelper.sfdxProjectArtifacts> artifactDirectories { get; set; }
    public SfdxAPIHelper.ScratchOrgDefinition orgDefinition { get; set; }
    public String parentId { get; set; }
    public String selectedStep { get; set; }
    private Map<Id, Deployment_Flow_Step__c> flowStepsMap { get; set; }
    public String deploymentFlowName { get; set; }
    public String selectedPermissions { get; set; }
    public List<SelectOption> dxTargetFlowSteps { get; set; }
    public Boolean showDeploymentFlow { get; set; }
    public Boolean showPermissionsPanel { get; set; }
    public Boolean showSetup { get; set; }
    public String depFlowId { get; set; }
    public String depFlowGitRepoId { get; set; }
    public String completionMessage { get; set; }
    public String sourceBranch { get; set; }
    public String sourceArtifacts { get; set; }
    public String sourceOrg { get; set; }
    public SfdxAPIHelper.ObjectLevelSecurity deploymentFlowSecurity { get; set; }
    public SfdxAPIHelper.ObjectLevelSecurity deploymentFlowStepSecurity { get; set; }
    public Test_Run__c tRun {get;set;}

    public ScratchOrgCompletionController() {
        deploymentFlowSecurity = SfdxAPIHelper.checkOLS(Schema.sObjectType.Deployment_Flow__c);
        deploymentFlowStepSecurity = SfdxAPIHelper.checkOLS(Schema.sObjectType.Deployment_Flow_Step__c);
        showDeploymentFlow = deploymentFlowSecurity.updateable && deploymentFlowStepSecurity.creatable;
        showPermissionsPanel = true;
        showSetup = true;
        flowStepsMap = new Map<Id, Deployment_Flow_Step__c>();

    }

    public PageReference createFullScratchOrg() {
        if(tRun != null && String.isNotBlank(tRun.Id)){
            String devHubId = tRun.Test_Script__r.User_Story__r.Org_Credential__r.Developer_Hub_Org__c;
            String sourceBranch = SfdxAPIHelper.DX_PROJECT_BRANCH+String.valueOf(tRun.Test_Script__r.User_Story__r.Org_Credential__c).substring(3,15);
            String soName = tRun.Name+' Scratch Org';
            String orgId = tRun.Test_Script__r.User_Story__r.Org_Credential__c;
            List<Attachment> attDefinition = [SELECT Body FROM Attachment WHERE ParentId =:orgId AND Name =: SfdxAPIHelper.DX_DEFINITION_FILE];
            String definitionBody = '';
            if(!attDefinition.isEmpty()){
                definitionBody = attDefinition[0].Body.toString();
            }
            List<Attachment> metadataSources = [SELECT Body FROM Attachment WHERE ParentId =:orgId AND Name =: SfdxAPIHelper.DX_METADATA_SOURCES];
            SfdxAPIHelper.ScratchOrgDefinition orgTemplate = (SfdxAPIHelper.ScratchOrgDefinition) JSON.deserialize(definitionBody, SfdxAPIHelper.ScratchOrgDefinition.class);
            orgTemplate.orgName = tRun.Name+' Scratch Org';
            orgTemplate.username = '';
            String oT = JSON.serialize(orgTemplate);
            String mdSource = '';
            if(metadataSources.size()>0){
                metadataSources[0].Body.toString();
            }
            System.debug(LoggingLevel.INFO,'***mdSource :'+mdSource);
            //DevHub // to calculate
            // Org Name Scratch Org Name
            //Source Branch should be dx branch

            SfdxAPI.fullScratchOrg(oT,devHubId,soName, 1,null,null, null, null, sourceBranch, null,null,mdSource,null,null,'false');
        } else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Test_Run_Is_Empty));
        }

        return null;
    }

    public String getFlowDXDestination(){
        return flowStepsMap.containsKey(selectedStep) && flowStepsMap.get(selectedStep) != null ? flowStepsMap.get(selectedStep).Source_Environment__c : null;
    }

    public void deploymentFlowOperations() {
        system.debug('ScratchOrgCompletionController_deploymentFlowOperations: '+ showDeploymentFlow);
        if (!showDeploymentFlow) return;
        depFlowId = String.valueOf(findDeploymentFlowId());
        if (depFlowId == null) showDeploymentFlow = false;
        Deployment_Flow__c depFlow = [
                SELECT Id, Name, (
                        SELECT Id,Name,Enable_as_Scratch_Org_Destination__c,Destination_Environment__c,
                                Destination_Environment__r.Name,Source_Environment__c,Source_Environment__r.Name
                        FROM Deployment_Flow_Steps__r
                        WHERE Enable_as_Scratch_Org_Destination__c != NULL
                )
                FROM Deployment_Flow__c
                WHERE Id = :depFlowId
                LIMIT 1
        ];
        deploymentFlowName = depFlow.Name;
        dxTargetFlowSteps = new List<SelectOption>();
        Id addedDefaultTarget;
        for (Deployment_Flow_Step__c dfs : depFlow.Deployment_Flow_Steps__r) {
            if(dfs.Enable_as_Scratch_Org_Destination__c == 'Default DX Target') {
                addedDefaultTarget = dfs.Id;
                String optionName = dfs.Source_Environment__r.Name + '-->' + dfs.Destination_Environment__r.Name;
                selectedStep = dfs.Source_Environment__c;
                dxTargetFlowSteps.add(new SelectOption(dfs.Source_Environment__c, optionName));
                flowStepsMap.put(dfs.Source_Environment__c,dfs);
                break;
            }
        }
        dxTargetFlowSteps.add(new SelectOption('', '-- None --'));
        for (Deployment_Flow_Step__c dfs : depFlow.Deployment_Flow_Steps__r) {
            if(addedDefaultTarget == dfs.Id) continue;
            String optionName = dfs.Source_Environment__r.Name + '-->' + dfs.Destination_Environment__r.Name;
            dxTargetFlowSteps.add(new SelectOption(dfs.Source_Environment__c, optionName));
            flowStepsMap.put(dfs.Source_Environment__c,dfs);
        }

    }

    private Id findDeploymentFlowId() {
        system.debug('ScratchOrgCompletionController_findDeploymentFLowId: '+ parentStandardControllerId);
        if (parentStandardControllerId == null) return null;
        if (parentStandardControllerType == Schema.SObjectType.User_Story__c.getSobjectType()) {
            User_Story__c us = [SELECT Id,Project__c,Project__r.Deployment_Flow__c,Project__r.Deployment_Flow__r.Git_Repository__c,Release__c,Release__r.Project__r.Deployment_Flow__c,Release__r.Project__r.Deployment_Flow__r.Git_Repository__c FROM User_Story__c WHERE Id = :parentStandardControllerId LIMIT 1];

            if (us.Project__r.Deployment_Flow__c != null) {
                depFlowGitRepoId = us.Project__r.Deployment_Flow__r.Git_Repository__c;
                system.debug('ScratchOrgCompletionController_depFlowGitRepoId: '+ depFlowGitRepoId);
                return us.Project__r.Deployment_Flow__c;
            } else if (us.Release__r.Project__r.Deployment_Flow__c != null) {
                depFlowGitRepoId = us.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c;
                system.debug('ScratchOrgCompletionController_depFlowGitRepoId: '+ depFlowGitRepoId);
                return us.Release__r.Project__r.Deployment_Flow__c;
            }
        }
        return null;
    }
}