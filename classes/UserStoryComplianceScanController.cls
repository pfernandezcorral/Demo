public with sharing class UserStoryComplianceScanController {
    public User_Story__c userStory {get; set;}
    
    public UserStoryComplianceScanController(ApexPages.StandardController std) {
        userStory = [SELECT Id, Org_Credential__c FROM User_Story__c WHERE Id = :std.getId() LIMIT 1];        
    }
    
    public void requestComplianceScan() {
        if(FeatureHelper.isComplianceHubEnabled()){
            if(LicenseHelper.actionIsLicenseEnabled('requestComplianceScan')){
                try {
                    DeployAPI.usComplianceScan(userStory.Org_Credential__c, userStory.Id);
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, Label.COMPLIANCE_SCAN_REQUESTED));
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                }
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, Label.CAD_License_Restriction));
            }
        } else {
            Apexpages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, Label.FEATURE_NOT_SUPPORTED+' Compliance Hub'));
        }
    }
}