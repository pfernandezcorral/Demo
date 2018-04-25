public without sharing class SeleniumTestRunTriggerHelper {
    public static boolean inTrigger = false;

    public static void updateGroups(){
        // check trigger flag to prevent concurrent updates with SeleniumTestGroupTriggerHelper.
        if(inTrigger)
            return;

        Set<Id> groupIds = new Set<Id>();
        if(Trigger.new !=null)for(SObject so:Trigger.new){
            Selenium_Test_Run__c tr = (Selenium_Test_Run__c)so;
            if(tr.Selenium_Test_Group__c !=null)groupIds.add(tr.Selenium_Test_Group__c);
        }
        if(Trigger.old !=null)for(SObject so:Trigger.old){
            Selenium_Test_Run__c tr = (Selenium_Test_Run__c)so;
            if(tr.Selenium_Test_Group__c !=null)groupIds.add(tr.Selenium_Test_Group__c);
        }
        Map<Id,String> existingGroupStatus = new Map<Id,String>();
        for(Selenium_Test_Group__c tg:[select Id, Status__c from Selenium_Test_Group__c where Id in:groupIds])
            existingGroupStatus.put(tg.Id, tg.Status__c);
        
        Map<Id,String> newGroupStatus = new Map<Id,String>();
        for(Selenium_Test_Run__c tr:[select Id, Last_Status__c, Selenium_Test_Group__c from Selenium_Test_Run__c where Selenium_Test_Group__c in:groupIds]){
            String id = tr.Selenium_Test_Group__c;
            String s = getGroupStatus(tr.Last_Status__c);
            
            System.debug('*** 1 '+id + ' - ' + tr.Last_Status__c+ ' - ' + s);
            if(newGroupStatus.get(id)==null){
             	newGroupStatus.put(id,s);
                System.debug('*** 2 '+id + ' - ' + newGroupStatus.get(id));
                continue;
            }
            if(s == 'In Progress')newGroupStatus.put(id,'In Progress');
            System.debug('*** 3 '+id + ' - ' + newGroupStatus.get(id));
            if(newGroupStatus.get(id) == 'In Progress')continue;
            if(newGroupStatus.get(id) == 'Completed Successfully' && s =='Completed with Errors')newGroupStatus.put(id,s);
            System.debug('*** 4 '+id + ' - ' + newGroupStatus.get(id));
        }
        List<Selenium_Test_Group__c> tobeUpdated = new List<Selenium_Test_Group__c>();
        for(Id id : newGroupStatus.keySet()){
            if(newGroupStatus.get(id)!= existingGroupStatus.get(id))
                tobeUpdated.add(new Selenium_Test_Group__c(Id = id, Status__c = newGroupStatus.get(id), Status_Date__c=System.now()));
        }
        System.debug('*** 5 '+ tobeUpdated);
        // Try to update, but if there is a concurrency error ( UNABLE_TO_LOCK_ROW ), just ignore the change
        try{
            update tobeUpdated;
		}catch(System.DmlException dmlEx) {
            System.debug('Got exception: '+dmlEx.getMessage());
            if (!dmlEx.getMessage().contains('UNABLE_TO_LOCK_ROW'))
                throw dmlEx;
        }
        SeleniumTestGroupTriggerHelper.changedStatuses = new Map<String,String>();
        for(Selenium_Test_Group__c g:tobeUpdated){
            SeleniumTestGroupTriggerHelper.changedStatuses.put(g.Id, g.Status__c);
        }
        SeleniumTestGroupTriggerHelper.sendCalloutsIfAny();
        
        inTrigger = false;
    }
    private static String getGroupStatus(String runStatus){
        if(runStatus == 'Starting' || runStatus == 'Queued') return 'In Progress';
        if(runStatus == 'Provider Failure') return 'Completed with Errors';
        return runStatus;
    }
}