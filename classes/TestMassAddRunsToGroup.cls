@isTest
public class TestMassAddRunsToGroup {
    @testSetup static void setupTestData(){
        TestUtilities.enableLicenses(10, 10, 10);
    }
    private static testMethod void TestMyLeadsController(){
        CMTestMethodUtilities.enableSelenium();
        Selenium_Settings__c s = new Selenium_Settings__c(Name = 'test settings', Webdriver_URL__c='http://drive.me');
        insert s;
        Selenium_Test_Group__c g = new Selenium_Test_Group__c(Name = 'test group', Selenium_Settings__c = s.id, Manage_Test_Runs_manually__c=true);
        insert g;
        Org__c org1 = testMethodUtilities.create('Test org1', 'sandbox', '', 'org-id-1', 'tk-1', 'test1@test.com', System.now());
        insert org1;
        Selenium_Test_Suite__c ts1 = new Selenium_Test_Suite__c(name='test suite1');
        insert ts1;

        Selenium_Test_Run__c tr = new Selenium_Test_Run__c(Name='test1',
                                                           Selenium_Test_Suite__c=ts1.Id,
                                                           Selenium_Settings__c=s.Id);
        List<Selenium_Test_Run__c> sels = new List<Selenium_Test_Run__c>();
        sels.add(tr);
            
		ApexPages.StandardSetController std = new ApexPages.StandardSetController(sels);
	    MassAddRunsToGroup custom  = new MassAddRunsToGroup(std);
		
		custom.Cancel();
		custom.add();
    }
}