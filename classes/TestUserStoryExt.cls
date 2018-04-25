@isTest
public class TestUserStoryExt {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
	static testMethod void testDeploymentFlow(){   
        insert TestUtilities.getTestSettings();
        Project__c testProject = CMTestMethodUtilities.createProject('My Project');
        Environment__c envDev1 = CMTestMethodUtilities.createEnvironment('Dev1', 'SFDC_OrgId');
        Environment__c envDev2 = CMTestMethodUtilities.createEnvironment('Dev2', 'SFDC_OrgId2');
        Environment__c envInt = CMTestMethodUtilities.createEnvironment('Int', 'SFDC_OrgId3');
        Environment__c envUAT = CMTestMethodUtilities.createEnvironment('UAT', 'SFDC_OrgId4');
        Environment__c envProd = CMTestMethodUtilities.createEnvironment('Prod', 'SFDC_OrgId5');
        insert new List<Environment__c>{envDev1, envDev2, envInt, envUAT, envProd};

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('OrgDev1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envDev1.Id);
        Org__c orgDev2 = CMTestMethodUtilities.createOrg('OrgDev2', 'Sandbox', null, 'SFDC_OrgId2', null, null, system.now(), envDev2.Id);
        Org__c orgInt = CMTestMethodUtilities.createOrg('OrgInt', 'Sandbox', null, 'SFDC_OrgId3', null, null, system.now(), envInt.Id);
        Org__c orgUAT = CMTestMethodUtilities.createOrg('OrgUAT', 'Sandbox', null, 'SFDC_OrgId4', null, null, system.now(), envUAT.Id);
        Org__c orgProd = CMTestMethodUtilities.createOrg('OrgProd', 'Production', null, 'SFDC_OrgId5', null, null, system.now(), envProd.Id);
        insert new List<Org__c>{orgDev1, orgDev2, orgInt, orgUAT, orgProd};
        
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flow.Id);
        Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(envDev2.Id, envInt.Id, flow.Id);
        Deployment_Flow_Step__c dfs3 = CMTestMethodUtilities.createFlowStep(envInt.Id, envUAT.Id, flow.Id);
        Deployment_Flow_Step__c dfs4 = CMTestMethodUtilities.createFlowStep(envUAT.Id, envProd.Id, flow.Id);
        insert new List<Deployment_Flow_Step__c>{dfs1, dfs2, dfs3, dfs4};

        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;

        Release__c release = CMTestMethodUtilities.createRelease('Release1');
        release.Project__c = testProject.Id;
        release.Base_Branch__c = 'int';
        insert release;
        
        User_Story__c userStory = CMTestMethodUtilities.createUserStory('MyStory1');
        userStory.Project__c = testProject.Id;
        insert userStory;
                
        Test.startTest();
        UserStoryExt ext = new UserStoryExt(new ApexPages.StandardController(userStory));
        System.assertEquals(false, ext.hasActiveDeploymentFlow);
        System.assertEquals(0, ext.visualFlowSteps.size());
        UserStoryExt.getisChatterEnabled();
        
        userStory.Environment__c = envDev1.Id;
        userStory.Org_Credential__c = orgDev1.Id;
        update userStory;
        UserStoryExt ext2 = new UserStoryExt(new ApexPages.StandardController(userStory));
        System.assertEquals(true, ext2.hasActiveDeploymentFlow);
        System.assertEquals(4, ext2.visualFlowSteps.size());

        Promotion__c promotionDev1ToInt = CMTestMethodUtilities.createPromotion(testProject.Id, envDev1.Id);
        promotionDev1ToInt.Status__c = 'Completed';
        insert promotionDev1ToInt;
        Promoted_User_Story__c promotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotionDev1ToInt.Id);
        insert promotedUserStory1;
        userStory.Environment__c = envInt.Id;
        userStory.Org_Credential__c = orgInt.Id;
        update userStory;
        UserStoryExt ext3 = new UserStoryExt(new ApexPages.StandardController(userStory));
        System.assertEquals(true, ext3.hasActiveDeploymentFlow);
        System.assertEquals(4, ext3.visualFlowSteps.size());

        userStory.Environment__c = envUAT.Id;
        userStory.Org_Credential__c = orgUAT.Id;
        userStory.Project__c = null;
        userStory.Release__c = release.Id;
        update userStory;
        UserStoryExt ext4 = new UserStoryExt(new ApexPages.StandardController(userStory));
        System.assertEquals(true, ext4.hasActiveDeploymentFlow);
        // The size is only 2 since there is no Promotion from Int to UAT
        System.assertEquals(2, ext4.visualFlowSteps.size());

        Promotion__c promotionIntToUAT = CMTestMethodUtilities.createPromotion(testProject.Id, envInt.Id);
        promotionIntToUAT.Status__c = 'Completed';
        insert promotionIntToUAT;
        Promoted_User_Story__c promotedUserStory2 = new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotionIntToUAT.Id);
        insert promotedUserStory2;
        userStory.Base_Branch__c = 'master';
        update userStory;
        UserStoryExt ext5 = new UserStoryExt(new ApexPages.StandardController(userStory));
        // Since there is a Promotion from Int to UAT, the path is complete from Dev1 to Prod
        System.assertEquals(4, ext5.visualFlowSteps.size());
        System.assertEquals(true, ext5.hasActiveDeploymentFlow);
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.USER_STORY_BASE_BRANCH_CONFLICT));

        Test.stopTest();
    }
    static testMethod void testValidationDeployment(){
        insert TestUtilities.getTestSettings();
        Project__c testProject = CMTestMethodUtilities.createProject('My Project');
        Environment__c envDev1 = CMTestMethodUtilities.createEnvironment('Dev1', 'SFDC_OrgId');
        Environment__c envInt = CMTestMethodUtilities.createEnvironment('Int', 'SFDC_OrgId3');
        insert new List<Environment__c>{envDev1, envInt};

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('OrgDev1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envDev1.Id);
        Org__c orgInt = CMTestMethodUtilities.createOrg('OrgInt', 'Sandbox', null, 'SFDC_OrgId3', null, null, system.now(), envInt.Id);
        insert new List<Org__c>{orgDev1, orgInt};
        
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs1 = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flow.Id);
        insert new List<Deployment_Flow_Step__c>{dfs1};

        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;

        Release__c release = CMTestMethodUtilities.createRelease('Release1');
        release.Project__c = testProject.Id;
        insert release;
        
        User_Story__c userStory = CMTestMethodUtilities.createUserStory('MyStory1');
        insert userStory;     

        UserStoryExt ext1 = new UserStoryExt(new ApexPages.StandardController(userStory));

        ext1.validateUserStory();
        System.assertEquals(false, ext1.enablePoller);
        ext1.waitForDeployment();
        System.assertEquals(false, ext1.enablePoller);
        System.assertEquals(false, ext1.showHideMsg);
        ext1.getIsPollerEnabled();
        System.assertEquals(false, ext1.enablePoller);

        userStory.Project__c = testProject.Id;
        userStory.Environment__c = envDev1.Id;
        userStory.Org_Credential__c = orgDev1.Id;
        update userStory;     

        UserStoryExt ext2 = new UserStoryExt(new ApexPages.StandardController(userStory));

        String uri = '/json/v1/promote/_someId_?sid=_sessionId_&url=_endPoint_&deploy=true&deploymentName=PromotedStory-test&checkOnly=false&singleStep=false&testLevel=NoTestRun';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

        ext2.validateUserStory();
        System.assertEquals(true, ext2.enablePoller);
        ext2.waitForDeployment();
        System.assertEquals(true, ext2.enablePoller);
        System.assertEquals(false, ext2.showHideMsg);        
        ext2.getIsPollerEnabled();
        System.assertEquals(true, ext2.enablePoller);

        Promoted_User_Story__c pus = [SELECT Id, Promotion__c FROM Promoted_User_Story__c WHERE User_Story__c = :userStory.Id LIMIT 1];
        System.assertEquals(true, pus != null);
        Deployment__c deployment1 = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(), orgDev1.Id, 'Deploy now', 'Scheduled');
        deployment1.Promotion__c = pus.Promotion__c;
        insert deployment1;
        System.assertEquals(true, deployment1.Id != null);

        ext2.waitForDeployment();
        System.assertEquals(true, ext2.enablePoller);
        System.assertEquals(true, ext2.showHideMsg); 
        ext2.getIsPollerEnabled();
        System.assertEquals(true, ext2.enablePoller);

        userStory = [SELECT Id, Last_Validation_Deployment__c FROM User_Story__c WHERE Id = :userStory.Id];
        System.assertEquals(deployment1.Id, userStory.Last_Validation_Deployment__c);       
    }

    static testMethod void testRelatedAlerts() {
        insert TestUtilities.getTestSettings();
        User_Story__c userStory = CMTestMethodUtilities.createUserStory('MyStory1');
        insert userStory;

        User_Story_Metadata__c usm = new User_Story_Metadata__c(
                Metadata_API_Name__c = 'Test__c',
                Status__c = Label.BACK_PROMOTED,
                User_Story__c = userStory.Id,
                Name = 'Test__c');
        insert usm;

        Org__c org = new Org__c(Name = 'Fake Org Test');
        insert org;
        Git_Org_Commit__c com = new Git_Org_Commit__c(Status__c = 'No changes', Org__c = org.Id);
        insert com;
        User_Story_Commit__c usc = new User_Story_Commit__c(User_Story__c = userStory.Id, Snapshot_Commit__c = com.Id);
        insert usc;

        Test.startTest();
        UserStoryExt ext1 = new UserStoryExt(new ApexPages.StandardController(userStory));
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.BACK_PROMOTED_METADATA));
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.COMMIT_NO_CHANGES));
        Test.stopTest();
    }
}