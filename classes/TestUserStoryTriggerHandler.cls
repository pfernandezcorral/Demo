@isTest
private class TestUserStoryTriggerHandler {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    @testSetup static void setupTestDataDML(){
        testMethodUtilities.upsertOrgwideSettings();
    }
    static testMethod void test_before_insert() {
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        insert testProject;
        
        Sprint__c testSprint = CMTestMethodUtilities.createSprint('my sprint');
        testSprint.Project__c = testProject.Id;
        insert testSprint;
        
        List<User_Story__c> userStories = new List<User_Story__c>();
        for(Integer i=0; i<20; i++){
        	User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        	testUserStory.Sprint__c = testSprint.Id;
        	testUserStory.Project__c = null;
        	userStories.add(testUserStory);
        }
        
        Test.startTest();
        insert userStories;
        Test.stopTest();
        
        for(User_Story__c u : [select Id, Project__c from User_Story__c]){
        	system.assertEquals(testProject.Id, u.Project__c);
        }
    }
    static testMethod void test_before_update() {
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        insert testProject;
        
        Sprint__c testSprint = CMTestMethodUtilities.createSprint('my sprint');
        testSprint.Project__c = testProject.Id;
        insert testSprint;
        
        List<User_Story__c> userStories = new List<User_Story__c>();
        for(Integer i=0; i<20; i++){
        	User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        	testUserStory.Sprint__c = null;
        	testUserStory.Project__c = null;
        	userStories.add(testUserStory);
        }
        insert userStories;
        
        for(User_Story__c u : userStories){
        	u.Sprint__c = testSprint.Id;
        	u.Project__c = null;
        }
        
        Test.startTest();
        update userStories;
        Test.stopTest();
        
        for(User_Story__c u : [select Id, Project__c from User_Story__c]){
        	system.assertEquals(testProject.Id, u.Project__c);
        }
    }
    static testMethod void test_with_Environment() {
        Environment__c env1 = new Environment__c(Name='Dev Environment');
        env1.Minimum_Apex_Test_Coverage__c = 85;
        insert env1;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;

        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        insert testProject;

        Sprint__c testSprint = CMTestMethodUtilities.createSprint('my sprint');
        testSprint.Project__c = testProject.Id;
        insert testSprint;
        
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        testUserStory.Sprint__c = testSprint.Id;
        testUserStory.Org_Credential__c = testOrg1.Id;
        insert testUserStory;
        testUserStory = [SELECT Id, Minimum_Apex_Code_Coverage__c FROM User_Story__c WHERE Id = :testUserStory.Id];
        System.assertEquals(85, testUserStory.Minimum_Apex_Code_Coverage__c);

        testUserStory.Minimum_Apex_Code_Coverage__c = 50;
        update testUserStory;
        testUserStory = [SELECT Id, Minimum_Apex_Code_Coverage__c FROM User_Story__c WHERE Id = :testUserStory.Id];
        System.assertEquals(85, testUserStory.Minimum_Apex_Code_Coverage__c);

        testUserStory.Minimum_Apex_Code_Coverage__c = 95;
        update testUserStory;
        testUserStory = [SELECT Id, Minimum_Apex_Code_Coverage__c FROM User_Story__c WHERE Id = :testUserStory.Id];
        System.assertEquals(95, testUserStory.Minimum_Apex_Code_Coverage__c);
    }
    static testMethod void deployPromotedUserStory(){
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;
        Environment__c env1 = new Environment__c(Name='UAT Environment');
        insert env1;
        Environment__c env2 = new Environment__c(Name='Production Environment');
        insert env2;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;
        
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;
        
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        testUserStory.Project__c = testProject.Id;
        insert testUserStory;
        
        String uri = '/json/v1/promote/_someId_?sid=_sessionId_&url=_endPoint_&deploy=true&deploymentName=PromotedStory-test&checkOnly=false&singleStep=false&testLevel=NoTestRun';
        
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
        
        testUserStory.Promote_and_Deploy__c = true;
        update testUserStory;

        
        List<Promotion__c> promoResult = [select Id, Name from Promotion__c];
        system.assertEquals(1, promoResult.size());
        
        List<Promoted_User_Story__c> pus = [select Id, Name, User_Story__r.Name from Promoted_User_Story__c where Promotion__c=:promoResult[0].Id];
        system.assertEquals(1, pus.size());
        system.assertEquals('Promoted User Story: '+pus[0].User_Story__r.Name, pus[0].Name);        
    }
}