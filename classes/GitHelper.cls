public class GitHelper {
    public static Map<String,ACommit>  commitMap = new Map<String,ACommit>();
    
    public static List<ACommit> getCommits(String repositoryId, String branch, Date fromDate, Date toDate, String startCommit, String endCommit, Integer lim){
        System.debug('Commit filter repositoryId = ' + repositoryId);
        System.debug('Commit from date = ' + fromDate);
        System.debug('Commit to date = ' + toDate);
        commitMap = new Map<String,ACommit>();
        List<ACommit> res = new List<ACommit>();
        
        List<Git_Org_Commit__c> list1 = new List<Git_Org_Commit__c>();
        if(String.isNotBlank(branch)){
            list1 = [select Commit_Id__c, Commit_Date__c, Commit_Message__c, Git_Backup__r.Branch__c from 
                                 Git_Org_Commit__c where 
                                 Git_Backup__r.Git_Repository__c=:repositoryId and
                                 Git_Backup__r.Branch__c=:branch and
                                 Commit_Date__c >=:fromDate and 
                                 Commit_Date__c <=:toDate and
                                 Status__c = 'Complete'
                                 order by Commit_Date__c desc, CreatedDate desc limit :lim];
        }
        else{
            list1 = [select Commit_Id__c, Commit_Date__c, Commit_Message__c, Git_Backup__r.Branch__c from 
                                 Git_Org_Commit__c where 
                                 Git_Backup__r.Git_Repository__c=:repositoryId and
                                 Commit_Date__c >=:fromDate and 
                                 Commit_Date__c <=:toDate and
                                 Status__c = 'Complete'
                                 order by Commit_Date__c desc, CreatedDate desc limit :lim];
        }
        for(Git_Org_Commit__c t:list1){
			//add commit without dupes
			if(!commitMap.containsKey(t.Commit_Id__c)){
                ACommit z = new ACommit(t.Commit_Id__c,t.Commit_Message__c,t.Commit_Date__c, t.Git_Backup__r.Branch__c);
				commitMap.put(t.Commit_Id__c,z);
                res.add(z);
            } 
        }
        System.debug('found ' + res.size() + ' git org commits for repository ' + repositoryId);
        List<Git_Commit__c> list2 = new List<Git_Commit__c>();
        if(String.isNotBlank(branch)){
            list2 = [select Commit_Id__c, Commit_Date__c, Commit_Message__c, Branch__c from 
                                 Git_Commit__c where 
                                 Git_Repository__c=:repositoryId and
                             	 Branch__c=:branch and
                                 Commit_Date__c >=:fromDate and 
                                 Commit_Date__c <=:toDate
                                 order by Commit_Date__c desc, CreatedDate desc limit :lim];
        }
        else{
            list2 = [select Commit_Id__c, Commit_Date__c, Commit_Message__c, Branch__c from 
                                 Git_Commit__c where 
                                 Git_Repository__c=:repositoryId and
                                 Commit_Date__c >=:fromDate and 
                                 Commit_Date__c <=:toDate
                                 order by Commit_Date__c desc, CreatedDate desc limit :lim];
        }
        for(Git_Commit__c t:list2){
			//add commit without dupes
			if(!commitMap.containsKey(t.Commit_Id__c)){
                ACommit z = new ACommit(t.Commit_Id__c,t.Commit_Message__c,t.Commit_Date__c, t.Branch__c);
				commitMap.put(t.Commit_Id__c, z);
                res.add(z);
            }
        }
        System.debug('total found ' + res.size() + ' git org commits and git commits for repository ' + repositoryId);
        res.sort();
        if(String.isNotBlank(startCommit) && String.isBlank(endCommit)){
            List<ACommit> t = new List<ACommit>();
            for(ACommit c:res){
                t.add(c);
                if(c.id == startCommit)break;
            }
            res = t;
        }
        return res;
    }
    
    public class ACommit implements Comparable{
        public String id{get;set;}
        public String message{get;set;}
        public DateTime cdate{get;set;}
        public String branch{get;set;}
        public ACommit(String id, String message, DateTime cdate, String branch){
            this.id = id;
            this.message = message;
            this.cdate = cdate;
            this.branch = branch;
        }
        public Integer compareTo(Object o){
            ACommit c = (ACommit)o;
            if(c.cdate > this.cdate)return 1;
            if(c.cdate < this.cdate)return -1;
            return 0;
        }
    }
}