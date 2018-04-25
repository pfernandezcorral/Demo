global with sharing class IndexMetadataJob implements Database.batchable<sObject>, Schedulable {
    public String userstoryId {get;set;}
	global Database.QueryLocator start(Database.BatchableContext BC){
		if(userstoryId != null) {
            return Database.getQueryLocator([select id from User_Story__c where Id = :userstoryId
                            AND Stop_Indexing_Metadata__c = false  AND Project__r.Index_Metadata__c = true]);
        } else return Database.getQueryLocator([select id from User_Story__c where Stop_Indexing_Metadata__c = false  
                                                AND Project__r.Index_Metadata__c=true]);
	}
	global void execute(Database.BatchableContext BC, List<User_Story__c> scope){
		Set<Id> uids = new Set<Id>();
		for(User_Story__c us : scope){
            uids.add(us.id);
		}
        Map<String,User_Story_Metadata__c> toBeUpserted = new Map<String,User_Story_Metadata__c>();
        for (Attachment att:[select Id, Name, Body, ParentId, Parent.Name from Attachment where parentId in :uids and name in ('MetaData','Delete MetaData', 'Git MetaData')]){
            try{
                String jsonInput = att.body.toString();
                List<Object> l = (List<Object>)JSON.deserializeUntyped(jsonInput);                
                for(Object o:l){
                    Map<String, Object> m = (Map<String, Object>)o;
                    User_Story_Metadata__c um = new User_Story_Metadata__c();
                    um.User_Story__c = att.ParentId;
                    um.Metadata_API_Name__c = m.get('t') + '.' + m.get('n');
                    um.Metadata_API_Name__c = um.Metadata_API_Name__c.left(255);
                    um.Unique_ID__c = att.ParentId + (att.Name=='Delete Metadata'?' _delete_':'_') + um.Metadata_API_Name__c;
                    um.Unique_ID__c = um.Unique_ID__c.left(255);
                    um.Name = att.Parent.Name + (att.Name=='Delete Metadata'?' Delete ':' ') + um.Metadata_API_Name__c;
                    um.Name = um.Name.left(80);
                    toBeUpserted.put(um.Unique_ID__c, um);
                }
            }
            catch(Exception e){
                System.debug('ERROR while parsing attachment ' + att.Name + ' - ' + att.Id + ' exception: ' + e.getMessage());
            }
        }
        Utilities.Secure_DML(toBeUpserted.values(), Utilities.DML_Action.UPS, schema.Sobjecttype.User_Story_Metadata__c, schema.sObjectType.User_Story_Metadata__c.fields.Unique_ID__c);     
	}
	global void finish(Database.BatchableContext BC){
        Set<String> dupes = new Set<String>();
        AggregateResult[] groupedResults = [SELECT Metadata_API_Name__c, count(Id) FROM User_Story_Metadata__c WHERE Status__c='' 
        and User_Story__r.Project__r.Index_Metadata__c=true AND User_Story__r.Stop_Indexing_Metadata__c = false GROUP BY Metadata_API_Name__c HAVING Count(Id) > 1];
        for (AggregateResult ar : groupedResults){
            String gname = Settings.ns+'Metadata_API_Name__c';
            String gr = ''+ar.get(gname);
            System.debug('***** grouped result name: ' + gname + ' value: ' + gr + ' all: ' + ar);
            dupes.add(gr);
        }
        List<User_Story_Metadata__c> toBeUpdated = new List<User_Story_Metadata__c>();
        for(User_Story_Metadata__c um : [Select Id from User_Story_Metadata__c where Metadata_API_Name__c in:dupes and Status__c='' 
            and User_Story__r.Project__r.Index_Metadata__c=true AND User_Story__r.Stop_Indexing_Metadata__c = false]){
            um.Status__c='Potential Conflict';
            toBeUpdated.add(um);
        }
        Utilities.Secure_DML(toBeUpdated, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story_Metadata__c);
	}
    global void execute(SchedulableContext sc) {
		IndexMetadataJob b = new IndexMetadataJob(); 
		database.executebatch(b,50);
   }
}