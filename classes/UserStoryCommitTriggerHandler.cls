public without sharing class UserStoryCommitTriggerHandler implements ITrigger{
 	public class ApplicationException extends Exception {}
    public UserStoryCommitTriggerHandler(){
    }
 
    public void bulkBefore(){
        UserSToryCommitTriggerHelper.prepareData();
    }
 
    public void bulkAfter(){
    }
 
    public void beforeInsert(SObject so){
        UserSToryCommitTriggerHelper.setNewDefaults((User_Story_Commit__c)so);
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
    }
    
    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
    }
 
    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){
        
    }
}