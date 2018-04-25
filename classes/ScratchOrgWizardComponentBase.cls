public with sharing virtual class ScratchOrgWizardComponentBase {
    public String scratchOrgCredentialId { get; set; }
    public String devHubOrgId { get; set; }
    public String deploymentFlowId { get; set; }
    public String deploymentFlowStepOption { get; set; }
    public String selectedOrgId { get; set; }
    public String selectedOrgIdFromDxOperation { get; set; }
    public String dxDeploymentFlowMode { get; set; }
    public String dxDeploymentFlowGitRepo { get; set; }
    public String dxBranchName { get; set; }
    public String dxUserStoryId { get; set; }
    public String dxUserStoryName { get; set; }
    public Object metadataSourceType { get; set; }
    public Object metadataSource { get; set; }

    static Set<String> componentModes = new Set<String>{
            'display',
            'edit',
            'wizard',
            'template',
            'new',
            'add',
            'editStd',
            'cloneStd'
    };
    /* Parameters for template buttons */
    public Boolean showButtons { get; set; }
    public Boolean showTemplateSaveAsButton { get; set; } // Respect OLS
    public Boolean showTemplateUpdateButton { get; set; } // Respect OLS
    public Boolean showTemplateButtons {
        get;
        set {
            if (value != null) {
                showTemplateButtons = value;
                showTemplateSaveAsButton = value;
                showTemplateUpdateButton = value;
            } else {
                showTemplateButtons = true;
                showTemplateSaveAsButton = true;
                showTemplateUpdateButton = true;

            }
            if (componentMode == 'editStd') {
                showTemplateSaveAsButton = false;
                showTemplateUpdateButton = true;
            } else if (componentMode == 'cloneStd') {
                showTemplateSaveAsButton = true;
                showTemplateUpdateButton = false;
            } else if(componentMode == 'add'){
                showTemplateSaveAsButton = true;
                showTemplateUpdateButton = true;
            }
        }
    } // Global attribute to pass to component
    public Boolean showComponent { get; set; }

    /* General parameters for wizard components */
    public List<SelectOption> devHubOrgIds { get; set; }
    public List<SelectOption> devHubs { get; set; }
    public String sourceSelections { get; set; }
    public Id parentStandardControllerId { get; set; }
    public Schema.sObjectType parentStandardControllerType { get; set; }


    public String componentMode {
        get;
        set {
            if (value != null && componentModes.contains(value)) {
                componentMode = value;
            } else {
                throw new componentSetupException('Component mode is required. Please assign'); // Internal error does not need a custom setting
            }
        }
    }
    public String controllerKey {
        get;
        set {
            if (value != null) {
                controllerKey = value;
                if (pageController != null)
                    pageController.setComponentControllerMap(controllerKey, this);
            }
        }
    }

    public ScratchOrgWizardPageBase pageController {
        get;
        set {

            if (value != null) {
                pageController = value;
                parentStandardControllerId = value.standardControllerID;
                if (parentStandardControllerId != null) {
                    parentStandardControllerType = parentStandardControllerId.getSObjectType();
                }
                pageController.setComponentController(this);
                if (pageController instanceof DXOperationController) {
                    String parentOperationDataId = ((DXOperationController) pageController).selectedOperationDataId;
                    String deploymentFlowMode = ((DXOperationController) pageController).dxDeploymentFlowMode;
                    Object attachmentMetadataSource = ((DXOperationController) pageController).metadataSource;
                    Object attachmentMetadataSourceType = ((DXOperationController) pageController).metadataSourceType;
                    String deploymentFlowGitRepo = ((DXOperationController) pageController).dxDeploymentFlowGitRepo;
                    String branchName = ((DXOperationController) pageController).dxBranchName;
                    String usId = ((DXOperationController) pageController).usId;
                    String usName = ((DXOperationController) pageController).usName;
                    System.debug('**f**usName : ' + usName);
                    if (String.isNotBlank(parentOperationDataId) && parentOperationDataId != '-- None --') {
                        devHubOrgId = parentOperationDataId; // for dev hub org
                        //selectedOrgId = parentOperationDataId; // for scratch org
                        selectedOrgIdFromDxOperation = parentOperationDataId; // for scratch org
                        metadataSource = attachmentMetadataSource; // for load metadata component
                        metadataSourceType = attachmentMetadataSourceType; // for load metadata component
                        dxDeploymentFlowMode = deploymentFlowMode; // for load metadata component
                        dxDeploymentFlowGitRepo = deploymentFlowGitRepo; // for load metadata component
                        dxBranchName = branchName; // for load metadata component
                    } else if(String.isNotBlank(usId)){
                        dxUserStoryId = usId;
                        dxUserStoryName = String.isNotBlank(usName) ? usName.replace('US-','SO-') : '';
                        System.debug('**f**dxUserStoryId : ' + dxUserStoryId);
                    }
                } else if(pageController instanceof CreateUserStoryScratchOrgController){
                    String usId = ((CreateUserStoryScratchOrgController) pageController).parentUS.Id;
                    String usName = ((CreateUserStoryScratchOrgController) pageController).parentUS.Name;
                    String depFlowMode = ((CreateUserStoryScratchOrgController) pageController).dxDeploymentFlowMode;
                    if(String.isNotBlank(usId)){
                        dxUserStoryId = usId;
                        dxUserStoryName = String.isNotBlank(usName) ? usName.replace('US-','SO-') : '';
                        if(String.isNotBlank(depFlowMode)){
                            dxDeploymentFlowMode = depFlowMode; // for load metadata component
                        }
                    }
                }
            }
        }
    }

    public virtual Boolean validateStep() {
        return true;
    }
    public virtual Boolean validateStep(Boolean skip) {
        return true;
    }

    public class componentSetupException extends Exception {
    }
}