public with sharing class EnvironmentTriggerHelper {
    public static Map<Id, Id> envsToUpdate; // map of environment id -> new Org_ID__c to update

    public static void prepareData(){
        envsToUpdate = new Map<Id, Id>();
        if(Trigger.newmap != null && Trigger.oldmap != null ) {
            for( Id envId : Trigger.newMap.keySet() ) {
                Id orgId = ((Environment__c)Trigger.newMap.get( envId )).Org_ID__c;
                if( String.isNotEmpty(orgId) && orgId != ((Environment__c)Trigger.oldMap.get( envId )).Org_ID__c ) {
                    envsToUpdate.put(envId, orgId);
                }
            }
        }
    }

    public static void updateOrgCredentials(){
        if(envsToUpdate==null) return;
        List<Org__c> orgsToUpdate = [SELECT Id, Environment__c, SFDC_Org_ID__c, Validated_Date__c FROM Org__c WHERE Environment__c IN :envsToUpdate.keySet()];
        for(Org__c org : orgsToUpdate) {
            List<String> ts = org.SFDC_Org_ID__c.split('_', 2);
            org.Validated_Date__c = null;
            org.oauth_signature__c = null;
            if(ts.size()>0) {
                ts[0] = envsToUpdate.get(org.Environment__c);
                org.SFDC_Org_ID__c = String.join(ts, '_');
            }else{
                System.debug('WARNING: an org credential had an invalid SFDC_Org_ID__c '+org.Id+' '+org.SFDC_Org_ID__c);
            }
        }
        Utilities.Secure_DML(orgsToUpdate, Utilities.DML_Action.UPS, schema.Sobjecttype.Org__c);
    }
}