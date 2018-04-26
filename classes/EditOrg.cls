public with sharing class EditOrg {
    public Org__c org {get; set;}
    public String dumypass {get; set;}
    public string metadata_url {get; set;}
    public boolean showUserPass {get; set;}

    public List<String> sel {get; set;}
    private List<String> metadataTypes;
    public List<SelectOption> types;
    public List<SelectOption> selectedTypes {get; set;}

    public Boolean hasTestResultAttachment {get; set;}
    public String resAttId {get; set;}
    public boolean isShareable {get; set;}
    public boolean scaAccess {get; set;}
    public boolean complianceScanResultAccess {get; set;}
    public Boolean showError {get; set;}
    public Boolean showOptions {get; set;}
    public Boolean complianceScanRequestAccess {get; set;}
    public Boolean isScratchOrg {get;set;}

    public EditOrg(apexpages.standardController std) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) std.addFields(new List<String>(Schema.SObjectType.Org__c.fields.getMap().keySet()));
        if (!Test.isRunningTest()) std.addFields(new List<String> {Settings.ns + 'Environment__r.Name', Settings.ns + 'is_Developer_Hub_Org__c'});

        showOptions = true;
        showError = false;
        scaAccess = FeatureAccessHelper.isSCAFeatureAccessible();
        complianceScanRequestAccess = LicenseHelper.actionIsLicenseEnabled('requestComplianceScan');
        complianceScanResultAccess = FeatureAccessHelper.isComplianceScanResultAccessible();
        hasTestResultAttachment = false;
        dumypass = '********';
        isLicenseEnabled();
        if (std.getId() != null) {
            org = utilities.getOrgById(std.getId());
        } else {
            org = new Org__c();
        }
        showUserPass = (org.password__c != null && org.oauth_signature__c == null) || Apexpages.currentPage().getParameters().get('showUserPass') == 'true';
        setUrls();

        isScratchOrg = String.isNotBlank(org.Org_Type__c) && org.Org_Type__c.startsWithIgnoreCase('Scratch Org');

        //****** selected types
        selectedTypes = new List<SelectOption>();
        sel = new List<String>();
        if (org.Metadata_Types__c != null) {
            for (String t : org.Metadata_Types__c.split(',')) {
                selectedTypes.add(new SelectOption(t, t));
                sel.add(t);
            }
        }
        sel.sort();

        //check apex test feature
        if (org.Test_Frequency__c != null && org.Test_Frequency__c != 'None' && !FeatureHelper.isFeatureEnabled('Apex Test') ) {
            org.Test_Frequency__c.addError(Label.FEATURE_NOT_SUPPORTED + ': Apex Test');
        }

        Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
        isShareable = tokens.containsKey('Org__Share');

        getTestResultAttachment();
    }

    public void getTestResultAttachment() {
        List<Apex_Test_Result__c> res = [select id from Apex_Test_Result__c where Org__c = :org.Id order by createddate desc limit 1];
        if (res.size() == 0)return;
        List<Attachment> atts = [select Id from Attachment where Name = 'ApexTestResult' and ParentId = :res.get(0).Id];
        if (atts.size() > 0) {
            this.hasTestResultAttachment = true;
            resAttId = atts.get(0).Id;
            //result = ApexTestResultCompController.buildApexResultsFromAttachment(resAtt.Id, null);
        }
    }

    public List<String> getMetadataTypes() {
        return MetadataTypesHelper.getMetadataTypesByOrgId(org.Id);
    }



    public List<SelectOption> getTypes() {

        return MetadataTypesHelper.getTypeOptionsByOrgId(org.Id, sel);

    }

    public void setTypes(List<SelectOption> l) {
        types = l;
    }



    public PageReference save() {
        //check apex test feature
        if (org.Test_Frequency__c != null && org.Test_Frequency__c != 'None' && !FeatureHelper.isFeatureEnabled('Apex Test') ) {
            org.Test_Frequency__c.addError(Label.FEATURE_NOT_SUPPORTED + ': Apex Test');
            return null;
        }

        //recover metadata types to save
        org.Metadata_Types__c = MetadataTypesHelper.joinOptions(selectedTypes);

        if (showUserPass == true && org.password__c != null)org.oauth_signature__c = null; //blank oauth
        Utilities.Secure_DML(org, Utilities.DML_Action.UPS, schema.Sobjecttype.Org__c);
        return new apexpages.standardController(org).view();
    }
    public PageReference addUserPass() {
        org.oauth_signature__c = null;
        showUserPass = true;
        PageReference pr = new apexpages.standardController(org).edit();
        pr.getParameters().put('showUserPass', 'true');
        return pr;
    }
    public PageReference doOauth() {
        String urlParameters = '?orgId=' + EncodingUtil.urlEncode(org.Id, 'UTF-8') + '&url=' + EncodingUtil.urlEncode([select API_URL__c from User where id = :userinfo.getUserId()].API_URL__c, 'UTF-8');
        if (org.Org_Type__c == 'Sandbox' || (String.isNotBlank(org.Org_Type__c) && org.Org_Type__c.startsWithIgnoreCase('Scratch Org'))) urlParameters += '&sandbox=true';
        if (org.Org_Type__c == 'Custom Domain') urlParameters += '&domain=' + EncodingUtil.urlEncode(org.Custom_Domain__c, 'UTF-8');
        urlParameters += '&copadoOrgId=' + EncodingUtil.urlEncode(userinfo.getOrganizationId(), 'UTF-8');
        urlParameters += '&copadoUserId=' + EncodingUtil.urlEncode(userinfo.getUserId(), 'UTF-8');
        urlParameters += '&signature=' + EncodingUtil.urlEncode(DeployAPI.encryptAPIKey(userinfo.getOrganizationId() + userinfo.getUserId()), 'UTF-8');
        String herokuServer = settings.Server_URL;
        String urlOauth = herokuServer + '/Authorize/sforceLogin' + urlParameters;
        PageReference pr = new PageReference(urlOauth);
        system.debug(pr);
        return pr;
    }
    public void setUrls() {
        //TODO: move this to external util method in order to use it in other classes
        String urlParameters = '';

        if (String.isNotBlank(org.Metadata_Types__c)) {
            urlParameters += '&filter=' + EncodingUtil.urlEncode(org.Metadata_Types__c, 'UTF-8');
        }

        String herokuServer = settings.Server_URL;
        String urlBase = herokuServer + '/json/v1/';
        if (org.Id == null)return;
        metadata_url = urlBase + 'metadata/' + EncodingUtil.urlEncode(org.Id, 'UTF-8') + '?dates=format' + urlParameters ;
    }
    public PageReference validate(){
        if(OrgTriggerHelper.isScheduled(org) && !FeatureHelper.isFeatureEnabled('Apex Test')){
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.error,Label.FEATURE_NOT_SUPPORTED+': Apex Test'));
            return null;
        }
        if(org.id != null && !org.Disable_Validation__c && !isScratchOrg){
            org = utilities.getOrgById(org.id);
            if(org.oauth_signature__c == null && org.password__c == null){
                Apexpages.addMessage(new apexpages.Message(apexpages.severity.info,Label.ADD_AUTHENTICATION));
                return null;
            }
            else{
                if (!DeployAPI.validateOrg(org.Id)){
                    Apexpages.addMessage(new apexpages.Message(apexpages.severity.error,Label.WRONG_CREDENTIALS));
                    return null;
                }
                else{
                    Apexpages.addMessage(new apexpages.Message(apexpages.severity.CONFIRM,Label.OK_CREDENTIALS));
                }
            }
            if(org.Test_Frequency__c!=null && org.Test_Frequency__c!='None'){
                Org__c copadoOrg = DeployAPI.getCustomerOrg();
                if(copadoOrg ==null){
                    Apexpages.addMessage(new apexpages.Message(apexpages.severity.error, Label.CUSTOMER_ORG_NOT_EXISTS));
                    return null;
                }
                if(!DeployAPI.validateOrg(copadoOrg.id)){
                    Apexpages.addMessage(new apexpages.Message(apexpages.severity.error, Label.CUSTOMER_ORG_NOT_VALIDATED));
                }
            }
        }

        return null;
    }

    public PageReference runAllTest() {
        if (!FeatureHelper.isFeatureEnabled('Apex Test')) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.error, Label.FEATURE_NOT_SUPPORTED + ': Apex Test'));
            return null;
        }
        if (!DeployAPI.validateOrg(org.Id)) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.error, Label.WRONG_CREDENTIALS));
            return null;
        }
        try {
            DeployAPI.testNow(org.id);
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.confirm, Label.TEST_REQUESTED));
        } catch (Exception e) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.error, '' + e.getMessage()));
        }
        return null;
    }
    public PageReference orgCodeAnalysis() {
        if (!FeatureHelper.isFeatureEnabled('Apex Test')) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.error, Label.FEATURE_NOT_SUPPORTED + ': Static Code Analysis'));
            return null;
        }
        if (!DeployAPI.validateOrg(org.Id)) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.error, Label.WRONG_CREDENTIALS));
            return null;
        }
        try {
            DeployAPI.orgCodeAnalysis(org.id);
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.confirm, Label.STATIC_CODE_ANALYSIS_REQUESTED));
        } catch (Exception e) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.error, '' + e.getMessage()));
        }
        return null;
    }

    public PageReference orgComplianceScan() {
        if (!FeatureHelper.isFeatureEnabled('Compliance Hub')) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.ERROR, Label.FEATURE_NOT_SUPPORTED + ': Compliance Hub'));
            return null;
        }

        if (!LicenseHelper.isCCHEnabled()) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.ERROR, Label.CCH_LICENSE_NOT_ENABLED));
            return null;
        }

        if (!DeployAPI.validateOrg(org.Id)) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.ERROR, Label.WRONG_CREDENTIALS));
            return null;
        }

        try {
            DeployAPI.orgComplianceScan(org.Id);
            ApexPages.getMessages().clear();
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.CONFIRM, Label.COMPLIANCE_SCAN_REQUESTED));
        } catch (Exception e) {
            Apexpages.addMessage(new apexpages.Message(apexpages.severity.ERROR, e.getMessage()));
        }

        return null;
    }

    public void isLicenseEnabled() {
        if (!LicenseHelper.actionIsLicenseEnabled('viewEditOrgCredential')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CAD_License_Restriction));
            showError = true;
            showOptions = false;
        }
        return;
    }

    public PageReference gotoDxOperations(){
        PageReference pRef = Page.DXOperation;
        if(String.isNotBlank(org.Id)){
            pRef.getParameters().put('id',org.Id);
        }
        pRef.setRedirect(true);
        return pRef;
    }

}