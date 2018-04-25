@isTest
public class TestSettings {
    @testSetup static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    @testSetup static void setupDataDML() {
        testMethodUtilities.upsertOrgwideSettings();
    }
    @isTest static void testFull(){   	

    	Test.startTest();

        Settings con = new Settings();
        System.assertNotEquals(null,con.urlBase);
        System.assertNotEquals(null,Settings.ns);
        System.assertNotEquals(null,Settings.copado_site);
        System.assertNotEquals(null,Settings.server_url);

        Test.stopTest();

    }
    static testMethod void testConstructors(){
        Settings s1 = new Settings(new ApexPages.StandardController(new Org__c()));
        Settings s2 = new Settings(new GitCommitLookupController());
        System.assert(s1 != s2);
    }
    
    static testMethod void testGitCommitChangesControllerInit(){
        Org__c o1 = testMethodUtilities.create('test', 'Production/Developer', null, null, null, null, System.now());
        insert o1;
        Git_Repository__c gr = testMethodUtilities.create('Test repo', 'test', 'test', 'testUri');
        insert gr;
        
        Git_Backup__c gitBackup = new Git_Backup__c(Name='test', Frequency__c='none', Org__c=o1.Id, Git_Repository__c=gr.Id);
        insert gitBackup;
        User_Story__c us = CMTestMethodUtilities.createUserStory('test');
        insert us;
        
        PageReference pref = new PageReference('/apex/test');
		pref.getParameters().put('snapshotId', gitBackup.Id);
        pref.getParameters().put('userStoryId', us.Id);
		Test.setCurrentPage(pref);
        
        Settings s = new Settings(new GitCommitChangesController());
        s.userStoryObj = us;
        String result = s.getUserStoryAsJSON();
                
        System.assertEquals(true, result.contains('User_Story__c'));        
    }

    static testMethod void testLicenseWrapper(){
        Settings.LicenseWrapper s = new Settings.LicenseWrapper(true,true,true,true,true,true);
        System.assertEquals(true,s.hasCAD);
        String currentLicenses = Settings.getCurrentUserLicenses();

    }
}