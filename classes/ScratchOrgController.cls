public with sharing class ScratchOrgController extends ScratchOrgWizardComponentBase {

    /* Scratch Org Definition component related parameters */
    public SfdxAPIHelper.ScratchOrgDefinition orgTemplate { get; set; }
    public Scratch_Org_Definition__c sod { get; set; }
    public Integer duration { get; set; }
    public String templateBody { get; set; }
    public String templateId { get; set{
        if(String.isNotBlank(value)){
            templateId = value;
        }
    } }
    public String templateName { get; set; }
    public List<String> enabledPreferences { get; set; }
    public List<String> disabledPreferences { get; set; }
    public String selectedPreferenceType { get; set; }
    private String lastPreferenceType;
    public List<SelectOption> preferenceTypes { get; set; }
    public List<SelectOption> dfsSelectOptionList {get; set;}
    public Boolean showTemplateFields { get; set; }
    public Map<String, List<SelectOption>> orgPreferences { get; set; }
    public List<SelectOption> countryPicklistOptions {get; set;}
    private Map<String, Set<String>> enabledOrgPreferences { get; set; }
    private Map<String, Set<String>> disabledOrgPreferences { get; set; }
    private Boolean typeChanged { get; set; }
    public String selectedDeploymentFlowStepOption {get; set;}

    public ScratchOrgController() {
        typeChanged = false;
        showTemplateFields = checkOLSAvailibility();
        if (!showTemplateFields) {
            showTemplateSaveAsButton = false;
            showTemplateUpdateButton = false;
        }
        if (devHubOrgId == null) getDevHubOrgs();
        System.debug(LoggingLevel.INFO,'***dxUserStoryName :'+dxUserStoryName);
        getOrgTemplateInstance();
        countryPicklistOptions = CountryPicklistValues.prepareCountryPicklist();
        orgPreferences = orgPreferencesHandler.prepareSelectOptions();
        templateId = null;
        templateName = '';
        duration = 7;

        selectedPreferenceType = 'General Settings';
        lastPreferenceType = 'General Settings';
        enabledPreferences = new List<String>();
        disabledPreferences = new List<String>();
        preferenceTypes = new List<SelectOption>();
        for (String op : orgPreferences.keySet()) {
            if (op != null)preferenceTypes.add(new SelectOption(op, op));
        }
    }
    private void getOrgTemplateInstance() {
        orgTemplate = new SfdxAPIHelper.ScratchOrgDefinition(null, 'US', null, UserInfo.getUserEmail(), 'Developer', null, false, 'en_US', new List<String>(), new SfdxAPIHelper.OrgPreferences());
    }
    public List<SelectOption> getDeploymentFlows(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('-- None --','-- None --'));
        for(Deployment_Flow__c df : [Select Id, Name From Deployment_Flow__c Where Enable_Copado_DX__c = true]){
            options.add(new SelectOption(df.Id,df.Name));
        }
        return options;
    }
    public void populateDeploymentFlowSteps(){
        if(String.isNotBlank(deploymentFlowId) && deploymentFlowId != '-- None --'){
            Deployment_Flow__c deploymentFlow = [SELECT Id, Name, (
                                                        SELECT Id,Name,Enable_as_Scratch_Org_Destination__c,Destination_Environment__c,
                                                                Destination_Environment__r.Name,Source_Environment__c,Source_Environment__r.Name
                                                        FROM Deployment_Flow_Steps__r
                                                        WHERE Enable_as_Scratch_Org_Destination__c != NULL
                                                )
                                                FROM Deployment_Flow__c
                                                WHERE Id = :deploymentFlowId
                                                LIMIT 1];

            if(String.isNotBlank(deploymentFlow.Id)){
                dfsSelectOptionList = new List<SelectOption>();
                Id addedDefaultTarget;
                for (Deployment_Flow_Step__c dfs : deploymentFlow.Deployment_Flow_Steps__r) {
                    if(dfs.Enable_as_Scratch_Org_Destination__c == 'Default DX Target') {
                        String optionName = dfs.Source_Environment__r.Name + '-->' + dfs.Destination_Environment__r.Name;
                        dfsSelectOptionList.add(new SelectOption(dfs.Source_Environment__c, optionName));
                        addedDefaultTarget = dfs.Id;
                        break;
                    }
                }
                dfsSelectOptionList.add(new SelectOption('-- None --', '-- None --'));
                for (Deployment_Flow_Step__c dfs : deploymentFlow.Deployment_Flow_Steps__r) {
                    if(addedDefaultTarget != dfs.Id) {
                        String optionName = dfs.Source_Environment__r.Name + '-->' + dfs.Destination_Environment__r.Name;
                        dfsSelectOptionList.add(new SelectOption(dfs.Source_Environment__c, optionName));
                    }
                }
            }
        }
    }
    private Boolean checkOLSAvailibility() {
        SfdxAPIHelper.ObjectLevelSecurity templateOLS = SfdxAPIHelper.checkOLS(Schema.sObjectType.Scratch_Org_Definition__c);
        if (templateOLS.accessible == false) return false;
        if (templateOLS.creatable == false) {
            showTemplateSaveAsButton = false;
        }
        if (templateOLS.updateable == false) {
            showTemplateUpdateButton = false;
        }
        return true;
    }
    public List<SelectOption> getTemlatesWithHubId(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('-- None --','-- None --'));
        if(String.isNotBlank(devHubOrgId)){
            for(Scratch_Org_Definition__c sog : [Select Id, Name From Scratch_Org_Definition__c Where Developer_Hub_Org__c =: devHubOrgId]){
                options.add(new SelectOption(sog.Id,sog.Name));
            }
        }else{
            for(Scratch_Org_Definition__c sog : [Select Id, Name From Scratch_Org_Definition__c Where Developer_Hub_Org__c != null]){
                options.add(new SelectOption(sog.Id,sog.Name));
            }
        }

        return options;
    }
    public void setLastSelection() {
        typeChanged = false;
        System.debug(loggingLevel.INFO, '*** lastPreferenceType: ' + lastPreferenceType);
        System.debug(loggingLevel.INFO, '*** selectedPreferenceType: ' + selectedPreferenceType);
        if (lastPreferenceType != selectedPreferenceType) {
            typeChanged = true;
        }
        lastPreferenceType = selectedPreferenceType;
        System.debug(loggingLevel.INFO, '*** typeChanged: ' + typeChanged);
        setSelectionsforEnabled();
        setSelectionsforDisabled();
        typeChanged = false;
    }
    public void setSelectionsforEnabled() {
        System.debug(loggingLevel.INFO, '*** typeChanged enable: ' + typeChanged);
        if (enabledOrgPreferences == null) {
            enabledOrgPreferences = new Map<String, Set<String>>();
        }
        Set<String> temp;
        if (enabledOrgPreferences.containsKey(lastPreferenceType) && typeChanged) {
            temp = enabledOrgPreferences.get(lastPreferenceType);
        } else {
            temp = new Set<String>();
        }

        temp.addAll(enabledPreferences);
        enabledOrgPreferences.put(lastPreferenceType, temp);
        System.debug(loggingLevel.INFO, '*** enabledOrgPreferences: ' + enabledOrgPreferences);
        Set<String> allSelections = new Set<String>();
        for (String all : enabledOrgPreferences.keySet()) {
            allSelections.addAll(enabledOrgPreferences.get(all));
        }
        System.debug(loggingLevel.INFO, '*** allSelections: ' + allSelections);

        orgTemplate.orgPreferences.enabled.clear();
        orgTemplate.orgPreferences.enabled.addAll(allSelections);
        enabledPreferences.clear();
        if (enabledOrgPreferences.containsKey(selectedPreferenceType)) {
            enabledPreferences.addAll(enabledOrgPreferences.get(selectedPreferenceType));
        }
        System.debug(loggingLevel.INFO, '*** enabledPreferences after: ' + enabledPreferences);
    }
    public void setSelectionsforDisabled() {
        System.debug(loggingLevel.INFO, '*** typeChanged disable: ' + typeChanged);
        System.debug('**f**disabledOrgPreferences : ' + disabledOrgPreferences);
        if (disabledOrgPreferences == null) {
            disabledOrgPreferences = new Map<String, Set<String>>();
        }
        Set<String> temp;
        System.debug(loggingLevel.INFO, '*** lastPreferenceType: ' + lastPreferenceType);
        System.debug('**f**disabledOrgPreferences.containsKey(lastPreferenceType) : ' + disabledOrgPreferences.containsKey(lastPreferenceType));
        if (disabledOrgPreferences.containsKey(lastPreferenceType) && typeChanged) {
            temp = disabledOrgPreferences.get(lastPreferenceType);
        } else {
            temp = new Set<String>();
        }
        System.debug(loggingLevel.INFO, '*** disabledPreferences before: ' + disabledPreferences);
        System.debug(loggingLevel.INFO, '*** temp: ' + temp);
        temp.addAll(disabledPreferences);
        disabledOrgPreferences.put(lastPreferenceType, temp);
        System.debug(loggingLevel.INFO, '*** disabledOrgPreferences after: ' + disabledOrgPreferences);
        Set<String> allSelections = new Set<String>();
        for (String all : disabledOrgPreferences.keySet()) {
            allSelections.addAll(disabledOrgPreferences.get(all));
        }
        System.debug(loggingLevel.INFO, '*** allSelections: ' + allSelections);

        orgTemplate.orgPreferences.disabled.clear();
        orgTemplate.orgPreferences.disabled.addAll(allSelections);
        System.debug(loggingLevel.INFO, '*** orgTemplate.orgPreferences.disabled: ' + orgTemplate.orgPreferences.disabled);
        disabledPreferences.clear();
        if (disabledOrgPreferences.containsKey(selectedPreferenceType)) {
            disabledPreferences.addAll(disabledOrgPreferences.get(selectedPreferenceType));
        }
        System.debug(loggingLevel.INFO, '*** disabledPreferences after: ' + disabledPreferences);
    }
/**
 * Creation scratch org
 * @see SfdxAPI
 * @see SfdxAPI.prepareOrgDefinition
 * {@link [SfdxAPI.class#prepareOrgDefinition()] [prepareOrgDefinition]}
 * @see SfdxAPI.createScratchOrg
 * @return [description]
 */
    public PageReference createOrg() {
        Boolean isValid = validateStep(false);
        if (!isValid) return null;
        orgTemplate.orgName = dxUserStoryName;
        templateBody = SfdxAPIHelper.prepareOrgDefinition(orgTemplate);
        String userStoryId = String.isNotBlank(dxUserStoryId) ? dxUserStoryId : '';
        SfdxAPI.orgCreate(templateBody, devHubOrgId, orgTemplate.orgName, duration, deploymentFlowId, deploymentFlowStepOption, userStoryId);

        PageReference pr = Page.DXOperation;
        if(String.isNotBlank(devHubOrgId)){
            pr.getParameters().put('id',devHubOrgId);
        }
        pr.setRedirect(true);
        return pr;
    }
    public override Boolean validateStep(Boolean skip) {
        if (devHubOrgId == null || devHubOrgId == '-- None --') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Please_select_hub));
            return false;
        } /*else if (!skip && String.isEmpty(orgTemplate.orgName)) {*/else if (!skip && String.isEmpty(dxUserStoryName)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Set_Org_Name));
            return false;
        } else if (duration == null || duration < 1 || duration > 30) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Scratch_Org_Duration_Validation));
            return false;
        } else if (String.isEmpty(orgTemplate.edition)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.Org_Edition_Validation));
            return false;
        }
        return true;
    }
    public PageReference newTemplate() {
        saveTemplate(true);
        return null;
    }
    public PageReference updateTemplate() {
        saveTemplate(false);
        return null;
    }
    public void saveTemplate(Boolean isNew) {
        if (String.isEmpty(templateName)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.SOD_Template_Name_Validation));
            return;
        }
        Boolean isValid = validateStep(true);
        if (!isValid) return;

        String templateBodyToSave;
        SfdxAPIHelper.ScratchOrgDefinition temp = orgTemplate;
        temp.orgName = null;
        temp.username = null;
        templateBodyToSave = SfdxAPIHelper.prepareOrgDefinition(temp);
        System.debug('**f**templateName : ' + templateName);
        System.debug('**f**devHubOrgId : ' + devHubOrgId);
        System.debug('**f**duration : ' + duration);
        System.debug('**f**templateBodyToSave : ' + templateBodyToSave);
        sod = new Scratch_Org_Definition__c(
                Name = templateName,
                Developer_Hub_Org__c = devHubOrgId,
                Duration_in_days__c = duration,
                Scratch_Org_Definition_JSON__c = templateBodyToSave
        );

        if (templateId != null && !isNew) sod.id = templateId;
        Utilities.Secure_DML(sod, Utilities.DML_Action.UPS, schema.sObjectType.Scratch_Org_Definition__c);
        templateId = sod.Id;
        if (isNew) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.DX_Template_Success));
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.DX_Template_Success_Update));
        }
    }

    public PageReference readOrgDefinitionFromTemplate() {
        ApexPages.getMessages().clear();
        getOrgTemplateInstance();
        enabledPreferences = new List<String>();
        disabledPreferences = new List<String>();
        System.debug(loggingLevel.INFO, '***1 templateId: ' + templateId);
        if(String.isBlank(templateId)){
            templateId = ApexPages.currentPage().getParameters().get('templateId');
        }
        System.debug(loggingLevel.INFO, '***2 templateId: ' + templateId);
        if (String.isBlank(templateId)) return null;
        try {
            Scratch_Org_Definition__c template = [SELECT Id,Name, Scratch_Org_Definition_JSON__c, Developer_Hub_Org__c, Duration_in_days__c FROM Scratch_Org_Definition__c WHERE Id = :templateId LIMIT 1];
            devHubOrgId = template.Developer_Hub_Org__c;
            System.debug(loggingLevel.INFO, '*** devHubOrgId: ' + devHubOrgId);
            duration = (Integer) template.Duration_in_days__c;
            templateName = template.Name;
            orgTemplate = (SfdxAPIHelper.ScratchOrgDefinition) JSON.deserialize(template.Scratch_Org_Definition_JSON__c, SfdxAPIHelper.ScratchOrgDefinition.class);
            enabledOrgPreferences = OrgPreferencesHandler.processPreSelections(orgTemplate.orgPreferences.enabled);
            disabledOrgPreferences = OrgPreferencesHandler.processPreSelections(orgTemplate.orgPreferences.disabled);

            if (enabledOrgPreferences.containsKey(selectedPreferenceType)) {
                enabledPreferences.clear();
                enabledPreferences.addAll(enabledOrgPreferences.get(selectedPreferenceType));
            }
            if (disabledOrgPreferences.containsKey(selectedPreferenceType)) {
                disabledPreferences.clear();
                disabledPreferences.addAll(disabledOrgPreferences.get(selectedPreferenceType));
            }
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, Label.Read_DX_Template_Error + ' : '+ex.getMessage()));
            System.debug(loggingLevel.Error, '*** ERROR : ' + ex.getMessage());
        }
        return null;
    }

    private void getDevHubOrgs() {
        devHubs = new List<SelectOption>();
        devHubs.addAll(SfdxAPIHelper.listDevHubOrgOptions());
    }
}