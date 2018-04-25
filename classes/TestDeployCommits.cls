@isTest
private class TestDeployCommits {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void sortList(){
        List<GitHelper.ACommit> li = new List<GitHelper.ACommit>();
        li.add(new GitHelper.ACommit('today','today', DateTime.now(), 'master'));
        DateTime yest = DateTime.now().addDays(-1);
		li.add(new GitHelper.ACommit('yesterday','yesterday', yest, 'master'));
        DateTime tomw = DateTime.now().addDays(1);
		li.add(new GitHelper.ACommit('tomorrow','tomorrow', tomw, 'master'));
        System.assertEquals('today', li.get(0).id);
        System.assertEquals('yesterday', li.get(1).id);
        System.assertEquals('tomorrow', li.get(2).id);
        li.sort();
        System.assertEquals('tomorrow', li.get(0).id);
        System.assertEquals('today', li.get(1).id);
        System.assertEquals('yesterday', li.get(2).id);
    }
    static testMethod void getCommits(){
        DateTime yest = DateTime.now().addDays(-1);
        DateTime lasty = DateTime.now().addYears(-2);
        DateTime tomw = DateTime.now().addDays(1);
        Git_Repository__c repo = new Git_Repository__c(name='test repo');
        insert repo;
        Git_Commit__c c1 = new Git_Commit__c(Commit_Id__c = 'today', Commit_Date__c = DateTime.now().date(), Git_Repository__c = repo.Id);
        insert c1;
        Git_Commit__c c2 = new Git_Commit__c(Commit_Id__c = 'yesterday', Commit_Date__c = yest.date(), Git_Repository__c = repo.Id);
        insert c2;
        Git_Commit__c c3 = new Git_Commit__c(Commit_Id__c = 'tomorrow', Commit_Date__c = tomw.date(), Git_Repository__c = repo.Id);
        insert c3;
        
        Org__c o = new Org__c (name='test org');
        insert o;
        Git_Backup__c snap = new Git_Backup__c(name='test snapshot', git_repository__c = repo.id, org__c = o.id);
        insert snap;
        Git_Org_Commit__c c22 = new Git_Org_Commit__c(Commit_Id__c = 'yesterday', Commit_Date__c = yest.date(), Git_Backup__c = snap.Id, org__c = o.id, Status__c='Complete');
        insert c22;
        Git_Org_Commit__c c4 = new Git_Org_Commit__c(Commit_Id__c = 'last 2 year', Commit_Date__c = lasty.date(), Git_Backup__c = snap.Id, org__c = o.id, Status__c='Complete');
        insert c4;
        
        DeployCommits dc = new DeployCommits();
        dc.repositoryId = repo.Id;
        
        List<GitHelper.ACommit> li = dc.getCommits();
        System.assertEquals(3, li.size());
        System.assertEquals('tomorrow', li.get(0).id);
        System.assertEquals('today', li.get(1).id);
        System.assertEquals('yesterday', li.get(2).id);
        
        dc.dateFrom.Commit_Date__c = lasty.date();
        li = dc.getCommits();
        System.assertEquals(4, li.size());
        System.assertEquals('tomorrow', li.get(0).id);
        System.assertEquals('today', li.get(1).id);
        System.assertEquals('yesterday', li.get(2).id);
        System.assertEquals('last 2 year', li.get(3).id);
    }
}