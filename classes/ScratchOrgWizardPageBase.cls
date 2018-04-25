public with sharing virtual class ScratchOrgWizardPageBase {

    private ScratchOrgWizardComponentBase myComponentController;
    private Map<String, ScratchOrgWizardComponentBase>componentControllerMap;
    public String wizardDevHubId {get;set;}
    public Id standardControllerID { get; set; }
    public SfdxAPIHelper.ScratchOrgDefinition orgTemplate { get; set; }
    public SfdxAPIHelper.sfdxProject artifactProject { get; set; }

    public virtual ScratchOrgWizardComponentBase getMyComponentController() {
        return myComponentController;
    }

    public virtual Map<String, ScratchOrgWizardComponentBase> getComponentControllerMap() {
        return componentControllerMap;
    }

    public virtual ScratchOrgWizardComponentBase getComponentController(String key) {
        return componentControllerMap.get(key);
    }

    public virtual void setComponentControllerMap(String key, ScratchOrgWizardComponentBase compController) {
        if (componentControllerMap == null)
            componentControllerMap = new Map<String, ScratchOrgWizardComponentBase>();
        componentControllerMap.put(key, compController);
    }

    public virtual void setComponentController(ScratchOrgWizardComponentBase compController) {
        myComponentController = compController;
    }

    public ScratchOrgWizardPageBase getThis() {
        return this;
    }
}