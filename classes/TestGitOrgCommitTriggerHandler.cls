@isTest
private class TestGitOrgCommitTriggerHandler {

    static testMethod void test_after_insert() {
        Integer BATCH_SIZE = 3;
        List<Org__c> testOrgs = new List<Org__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            Org__c testOrg = testMethodUtilities.create('My test org' + i, 'Production', '', 'testOrgId' + i, '', '', null);
            testOrg.Last_Git_Backup_Datetime__c = null;
            testOrg.Last_Git_Backup_Status__c = '';
            testOrgs.add(testOrg);
        }
        insert testOrgs;

        List<Git_Org_Commit__c> testGOCs = new List<Git_Org_Commit__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            Git_Org_Commit__c testGoc = new Git_Org_Commit__c(
            Status__c = 'In Progress');
            testGoc.Org__c = testOrgs[i].Id;
            
            testGOCs.add(testGoc);
        }
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        insert testUserStory;


        Test.startTest();
        insert testGOCs;
        List<Git_Org_Commit__c> updateGOCs = new List<Git_Org_Commit__c>();
        List<User_Story_Commit__c> usCommits = new List<User_Story_Commit__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            User_Story_Commit__c usCommit = new User_Story_Commit__c(

                User_Story__c = testUserStory.Id,
                Snapshot_Commit__c = testGOCs[i].Id
            );
            usCommits.add(usCommit);
            Git_Org_Commit__c temp = testGOCs[i];
            temp.Status__c = 'Complete';
            temp.Commit_ID__c = '213234283748243' + i;
            updateGOCs.add(temp);
        }
        insert usCommits;
        
        update updateGOCs;
        Test.stopTest();

        Set<Id> resultIdSet = new Set<Id>();
        for (Git_Org_Commit__c g : testGOCs) {
            resultIdSet.add(g.Id);
        }

        List<Git_Org_Commit__c> results = [select Id, Commit_Date__c, Org__c, Org__r.Last_Git_Backup_Status__c, Org__r.Last_Git_Backup_Datetime__c from Git_Org_Commit__c where Id IN :resultIdSet];
        system.assertEquals(3, results.size());
        for (Git_Org_Commit__c g : results) {
            system.assert(g.Org__r.Last_Git_Backup_Datetime__c != null);
            system.assertEquals('OK', g.Org__r.Last_Git_Backup_Status__c);
            system.assertNotEquals(null, g.Commit_Date__c);
        }
    }
}