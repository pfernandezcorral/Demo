public without sharing class ComplianceFindingTriggerHandler implements ITrigger {
   
    public ComplianceFindingTriggerHandler(){
    }
 
    public void bulkBefore(){
    }
 
    public void bulkAfter(){
        ComplianceFindingTriggerHelper.updateComplianceScanResults();
    }
 
    public void beforeInsert(SObject so){
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