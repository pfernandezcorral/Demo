@isTest
private class TestUserStoryCommitTrigger {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void test_new_defaults(){
        Org__c o = new Org__c(name = 'test');
        insert o;
        Git_Repository__c r = new Git_Repository__c(name='test');
        insert r;
        Git_Backup__c bk = new Git_Backup__c(Git_Repository__c = r.id, Org__c = o.id);
        insert bk;
        Git_Org_Commit__c c = new Git_Org_Commit__c(Git_Backup__c = bk.id, Org__c = o.id, Commit_Id__c='b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c=Date.today(),Commit_Message__c='test', Status__c='Complete');
        insert c;
        User_Story__c us = new User_Story__c();
        insert us;
        String usName = [select Name from User_Story__c where id=:us.Id].Name;
        User_Story_Commit__c uc = new User_Story_Commit__c(User_Story__c = us.id, Snapshot_Commit__c = c.id);
        insert uc;
        User_Story_Commit__c afer = [select name, external_id__c from User_Story_Commit__c where Id= :uc.id];
        System.assertEquals(usName+' b7adccf', afer.Name);
        System.assertEquals(us.Id+'_b7adccf3937495e8928d1023c5a5c644198b8974', afer.external_id__c);
        update uc;
        delete uc;
        undelete uc;
    }
}