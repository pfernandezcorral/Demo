/**
 * Extension of New, Edit and view page for External CI Setting object.
 *
 * New, Edit and View pages are overriden by custom visualforce pages.
 * @author Mert YALTI
 * @date 15.06.2017
 * @see EditExternalCISettings
 * @see ViewExternalCISettings
 */
public with sharing class EditExternalCISetting {

    public External_CI_Setting__c externalCISetting {get; set;}
    private String settingId {get; set;}
    public List<External_CI_Job__c> jobs {get; set;}
    public Boolean showError {get;set;} 
    public Boolean showOptions {get;set;}

    public EditExternalCISetting(ApexPages.StandardController std) {
        showOptions = true;
        showError = false;
        isLicenseEnabled();
        External_CI_Setting__c setting = (External_CI_Setting__c)std.getRecord();
        settingId = setting.Id;
        if (std.getId() != null) {
            externalCISetting = Utilities.getCISettingById(std.getId());
        } else {
            externalCISetting = new External_CI_Setting__c();
        }
        getRelated();
    }
    /**
     * This method works as a standard save function
     * @see Utilities
     * @return PageReference
     */

    public void isLicenseEnabled(){
        if (!LicenseHelper.actionIsLicenseEnabled('viewEditExternalCI')){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CAD_License_Restriction));
            showError = true;
            showOptions = false;
        }
        return;
    } 
    public PageReference save() {
        if (externalCISetting.Endpoint__c != null) {
            Pattern urlValidator = Pattern.compile('^(http(s?):\\/\\/|ftp:\\/\\/)#*?([a-z_\\/0-9\\-\\#=&\\.\\:\\/])*');
            Matcher validate = urlValidator.matcher(externalCISetting.Endpoint__c);
            if (!validate.matches()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, Label.PLEASE_ENTER_VALID_URL));
                return null;
            } else {
                Utilities.Secure_DML(externalCISetting, Utilities.DML_Action.UPS, schema.Sobjecttype.External_CI_Setting__c);
                settingId = externalCISetting.Id;
                return new apexpages.standardController(externalCISetting).view();
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, Label.PLEASE_ENTER_VALID_URL));
            return null;
        }
    }
    public void getRelated() {
        jobs = ExternalCIAPIFactory.queryAllValues('External_CI_Job__c', 'External_CI_Setting__c', externalCISetting.Id, '', '');
    }
    
    public PageReference validate() {
        return EditExternalCISetting.validateConnection(externalCISetting);
    }
    /**
     * This method validates given credentials against selected CI Tool and its endpoint
     * @param externalCISetting External CI Setting record to validate it's credentials.
     * @see DeployAPI
     * @see ExternalCIAPIFactory
     * @return PageReference
     */
    public static PageReference validateConnection(External_CI_Setting__c externalCISetting){
        String endP = [Select Id, API_URL__c from User where Id = : UserInfo.getUserId()].API_URL__c;
        ExternalCIAPIFactory factory = new ExternalCIAPIFactory(externalCISetting.Id);
        /**
         * URL Parameters
         * sid = salesforce session id
         * url = user's API URL
         * uri = External CI system endpoint
         * un = External CI system user name
         * pw = External CI system api token
         */

        String url = DeployAPI.copadoURL + '/json/v1/validateXCI/' + externalCISetting.Id;
        url += '?uri=' + EncodingUtil.urlEncode(externalCISetting.Endpoint__c, 'UTF-8') + '&type=' + externalCISetting.CI_Tool__c;
        if (String.isNotBlank(externalCISetting.Username__c)) url += '&un=' + EncodingUtil.urlEncode(externalCISetting.Username__c, 'UTF-8');
        if (String.isNotBlank(externalCISetting.Password__c))url += '&pw=' + EncodingUtil.urlEncode(externalCISetting.Password__c, 'UTF-8');
        if (String.isNotBlank(externalCISetting.API_Token__c))url += '&tk=' + EncodingUtil.urlEncode(externalCISetting.API_Token__c, 'UTF-8');
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = factory.sendRequest(url, 'GET', null, true);

        ExternalCIAPIFactory.Validate isValid = (ExternalCIAPIFactory.Validate)factory.parseResponseBody('Validate', res);

        if (!isValid.success) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.WRONG_CREDENTIALS));
            return null;
        } else {
            try {
                externalCISetting.Credential_Validated__c = true;
                Utilities.Secure_DML(externalCISetting, Utilities.DML_Action.UPD, schema.Sobjecttype.External_CI_Setting__c);
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.FAILED));
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.OK_CREDENTIALS));
            return null;
        }
        return null;
    }
}