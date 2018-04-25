public without sharing class GitOrgCommitTriggerHelper {
	public static Map<Id, Org__c> orgMap = new Map<Id, Org__c>();
	public static Map<Id, User_Story__c> usToUpdate = new Map<Id, User_Story__c>();
	public static void updateOrgLastCommit(Git_Org_Commit__c goc) {
		Org__c org = new Org__c();
		org.id = goc.Org__c;
		org.Last_Git_Backup_Datetime__c = goc.createdDate;
		org.Last_Git_Backup_Status__c = 'OK';
		orgMap.put(goc.Org__c, org);
	}
	public static void setCommitDate(Git_Org_Commit__c goc) {
		if (goc.Commit_Date__c == NULL && !String.isBlank(goc.Commit_ID__c)){
			goc.Commit_Date__c = System.now();
		}
	}
	/**
	 * Populate or override Latest commit date on the US layout.
	 * @author Mert YALTI
	 * @param oldSObject Map<Id,Git_Org_Commit__c> 
	 * @param newsObject Map<Id,Git_Org_Commit__c> 
	 */
	public static void prepareLatestCommitDateData(Map<Id, sObject> oldSObject, Map<Id, sObject> newsObject) {
		Map<Id,Git_Org_Commit__c> oldGoc = (Map<Id,Git_Org_Commit__c>)oldSObject;
		Map<Id,Git_Org_Commit__c> newGoc = (Map<Id,Git_Org_Commit__c>)newsObject;
		Map<Id, Git_Org_Commit__c> completedOrgCommits = new Map<Id, Git_Org_Commit__c>();
		for (Git_Org_Commit__c goc : newGoc.Values()) {
			if ((oldGoc != null && oldGoc.ContainsKey(goc.Id) && oldGoc.get(goc.Id).Status__c != goc.Status__c && goc.Status__c == 'Complete') || (oldGoc == null && goc.Status__c == 'Complete') ) {
				completedOrgCommits.put(goc.Id, goc); //Completed commits
			}
		}
		Map<Id, Set<Id>> commitUSMap = new Map<Id, Set<Id>>(); // commits to US map in order to update proper US.
		Set<Id> userStories = new Set<Id>();
		for (User_Story_Commit__c usc : [SELECT Id, User_Story__c, Snapshot_Commit__c FROM User_Story_Commit__c WHERE Snapshot_Commit__c IN: completedOrgCommits.keySet()]) {
			userStories.add(usc.User_Story__c); // Set of US Ids for querying them
			if (commitUSMap.containsKey(usc.Snapshot_Commit__c)) {
				Set<Id> temp = commitUSMap.get(usc.Snapshot_Commit__c);
				temp.add(usc.User_Story__c);
				commitUSMap.put(usc.Snapshot_Commit__c, temp);
			} else {
				Set<Id> temp = new Set<Id>();
				temp.add(usc.User_Story__c);
				commitUSMap.put(usc.Snapshot_Commit__c, temp);
			}
		}		
		
		Map<Id, User_Story__c> usMap = new Map<Id, User_Story__c>([SELECT Id, Latest_Commit_Date__c FROM User_Story__c WHERE Id IN: userStories]);
		for (Id gocId : completedOrgCommits.keySet()) {
			if (commitUSMap.containsKey(gocId)) {
				for (Id usId : commitUSMap.get(gocId)) {
					User_Story__c tempUS = usMap.containsKey(usId) ? usMap.get(usId) : NULL;
					System.debug(loggingLevel.Error, '*** tempUS: ' + tempUS);
					if (tempUS == NULL || (tempUS != NULL && tempUS.Latest_Commit_Date__c > newGoc.get(gocID).Commit_Date__c) ) {
						System.debug(loggingLevel.Error, '*** continue first: ');
						continue;
					}
					//A user story may have more than one commit so beloow if else block checks which commit has the latest commit date.
					if (usToUpdate.containsKey(usId)) {
						User_Story__c overlapCheck = usToUpdate.get(usId);
						if (newGoc.get(gocID).Commit_Date__c < overlapCheck.Latest_Commit_Date__c) {
							continue;
						}
						tempUS.Latest_Commit_Date__c = newGoc.get(gocID).Commit_Date__c;
						usToUpdate.put(usId, tempUS);
					} else {
						tempUS.Latest_Commit_Date__c = newGoc.get(gocID).Commit_Date__c;
						usToUpdate.put(usId, tempUS);
					}

				}
			}
		}
		usMap.clear();
	}
	public static void updateLatestCommitDates(){
		if(usToUpdate != null && usToUpdate.values().size() > 0){
			Utilities.Secure_DML(usToUpdate.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
		}
	}
}