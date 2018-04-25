public with sharing class UserStoryCodeAnalysisRequestController {
    public User_Story__c userStory {get; set;}
    
    public UserStoryCodeAnalysisRequestController(ApexPages.StandardController std) {
        userStory = [SELECT Id, Org_Credential__c FROM User_Story__c WHERE Id = :std.getId() LIMIT 1];                
    }
    
    public void requestCodeScan() {
        try {
            if(LicenseHelper.actionIsLicenseEnabled('requestStaticCodeAnalysis')){
                DeployAPI.usCodeAnalysis(userStory.Org_Credential__c, userStory.Id);
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, Label.USER_STORY_ANALYSIS_REQUESTED));
            } else {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, Label.CAD_License_Restriction));
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
        }
    }
}