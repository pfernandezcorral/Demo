@isTest
public class TestUserStoryApexTestResultsExtension {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void test_missingSourceOrg(){
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        insert testProject;
        
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        testUserStory.Org_Credential__c = null;
        testUserStory.Project__c = testProject.Id;
        insert testUserStory;
        
        PageReference pageRef = new PageReference('apex/UserStoryApexTestResults?id='+testUserStory.Id);
        Test.setCurrentPageReference(pageRef);
        UserStoryApexTestResultsExtension ext = new UserStoryApexTestResultsExtension(new ApexPages.StandardController(testUserStory));
        
        Test.startTest();
        system.assert(testMethodUtilities.hasMessage('This user story does not have a source org. Please add a Source Org to the User Story and try again.'));
        Test.stopTest();
    }
    static testMethod void test_invalidOrg(){
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        insert testProject;
        
        Org__c testOrg1 = testMethodUtilities.create('MyOrg1', 'Production', null, 'RandomOrgId1', null, null, null);
        insert testOrg1;
        
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        testUserStory.Org_Credential__c = testOrg1.Id;
        testUserStory.Project__c = testProject.Id;
        insert testUserStory;
        
        PageReference pageRef = new PageReference('apex/UserStoryApexTestResults?id='+testUserStory.Id);
        Test.setCurrentPageReference(pageRef);
        UserStoryApexTestResultsExtension ext = new UserStoryApexTestResultsExtension(new ApexPages.StandardController(testUserStory));
        
        Test.startTest();
        system.assert(testMethodUtilities.hasMessage('The selected org is not validated.'));
        Test.stopTest();
    }
    static testMethod void test_goodOrg_noAttachment(){
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        insert testProject;
        
        Org__c testOrg1 = testMethodUtilities.create('MyOrg1', 'Production', null, 'RandomOrgId1', null, null, system.now());
        insert testOrg1;
        
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        testUserStory.Org_Credential__c = testOrg1.Id;
        testUserStory.Project__c = testProject.Id;
        insert testUserStory;
        
        PageReference pageRef = new PageReference('apex/UserStoryApexTestResults?id='+testUserStory.Id);
        Test.setCurrentPageReference(pageRef);
        UserStoryApexTestResultsExtension ext = new UserStoryApexTestResultsExtension(new ApexPages.StandardController(testUserStory));
        
        Test.startTest();
        system.assert(testMethodUtilities.hasMessage('This user story has no Apex Test Results. Press the \'Run Tests\' button.'));
        system.assertEquals(false, ext.hasAttachment);
        Test.stopTest();
    }
    static testMethod void test_goodOrg_withAttachment(){
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        insert testProject;
        
        Org__c testOrg1 = testMethodUtilities.create('MyOrg1', 'Production', null, 'RandomOrgId1', null, null, system.now());
        insert testOrg1;
        
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        testUserStory.Org_Credential__c = testOrg1.Id;
        testUserStory.Project__c = testProject.Id;
        insert testUserStory;
        
        Apex_Test_Result__c testResult = new Apex_Test_Result__c();
        testResult.Org__c = testOrg1.Id;
        insert testResult;
        
        Attachment att1 = new Attachment();
        att1.ParentId = testResult.id;
        att1.Name = 'ApexTestResult';
        att1.Body = Blob.valueOf('{"failures":0,"coverageWarning":"Average test coverage across all Apex Classes and Triggers is 69%, at least 75% test coverage is required.","time":333,"errors":true,"testClassResults":{"classCoverageResults":{"methods":[{"message":"","name":"test_after_insert_Errors","success":true},{"message":"TEST FAILED","name":"test_after_insert_OKs","success":false}]},"copado__UserStoryTrigger":{"methods":[{"message":"","name":"testBackup_errors_CustomerOrgMissing","success":true},{"message":"","name":"testBackup_success","success":true}]}},"tests":88,"details":"For details visit the Apex Test Results page from Salesforce setup.","classCoverageResults":{"copado__ApexResultsObject":{"coverage":0},"copado__UserStoryTrigger":{"coverage":100}}}');
        insert att1;
        
        PageReference pageRef = new PageReference('apex/UserStoryApexTestResults?id='+testUserStory.Id);
        Test.setCurrentPageReference(pageRef);
        UserStoryApexTestResultsExtension ext = new UserStoryApexTestResultsExtension(new ApexPages.StandardController(testUserStory));
        
        Test.startTest();
        system.assertEquals(true, ext.hasAttachment);
        Test.stopTest();
    }
}