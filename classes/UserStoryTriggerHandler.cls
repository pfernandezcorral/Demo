public without sharing class UserStoryTriggerHandler implements ITrigger{
    
 
    public UserStoryTriggerHandler(){
    }
 
    public void bulkBefore(){
    	UserStoryTriggerHelper.prepareMaps();
    }
 
    public void bulkAfter(){
    }

    public void beforeCommon(SObject oldSo, SObject so) {
        UserStoryTriggerHelper.setProject((User_Story__c)so);
        UserStoryTriggerHelper.setEnvironment((User_Story__c)so);
        UserStoryTriggerHelper.validateOrgEnvironmentRelationship((User_Story__c)so);
        UserStoryTriggerHelper.checkSprints((User_Story__c)oldSo, (User_Story__c)so);
    }
 
    public void beforeInsert(SObject so){
    	beforeCommon(null, so);
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
    	beforeCommon(oldSo, so);
        
    }
    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
        UserStoryTriggerHelper.addUserStoryToPromoteDeployQueue((User_Story__c)oldSo, (User_Story__c)so);
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
        UserStoryTriggerHelper.promoteAndDeployUserStories();
    }
}