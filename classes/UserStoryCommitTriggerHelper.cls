public without sharing class UserStoryCommitTriggerHelper {
	public static Map<String,String> cmMap = new Map<String,String>();
    public static Map<String,String> usMap = new Map<String,String>();
    public static void prepareData(){
        if(Trigger.isInsert){
         	for(SObject so:Trigger.new){
                User_Story_Commit__c uc = (User_Story_Commit__c)so;
                cmMap.put(uc.Snapshot_Commit__c,null);
                usMap.put(uc.User_Story__c, null);
            }
            for(Git_Org_Commit__c c:[Select Id,Commit_Id__c from Git_Org_Commit__c where id in:cmMap.keySet()]){
                cmMap.put(c.Id, c.Commit_Id__c);
            }
            for(User_Story__c us:[Select Id,Name from User_Story__c where id in:usMap.keySet()]){
                usMap.put(us.Id, us.Name);
            }   
        }
    }
    public static void setNewDefaults(User_Story_Commit__c c){
        if(!(usMap.get(c.User_Story__c) !=null && cmMap.get(c.Snapshot_Commit__c)!=null && cmMap.get(c.Snapshot_Commit__c).length() >30))return;
        c.Name = usMap.get(c.User_Story__c) + ' ' + cmMap.get(c.Snapshot_Commit__c).substring(0,7);
        c.External_Id__c = c.User_Story__c + '_' + cmMap.get(c.Snapshot_Commit__c);
    }
}