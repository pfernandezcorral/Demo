@isTest
private class TestGlobalUtilities {
    @testSetup static void setupTestData(){
        TestUtilities.getAllMultilicense();
    }
    @testSetup static void setupTestDataDML(){
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        testMethodUtilities.upsertOrgwideSettings();
    }
    static testMethod void testDeploymentFlowDetails() {
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('simple flow', true);
        insert flow;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        insert env1;
        Environment__c env2 = new Environment__c(Name = 'Integration Environment', Type__c = 'Production');
        insert env2;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;

        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;
        Deployment_Flow_Step__c dfs2 = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowCBM.Id);
        dfs2.Branch__c = 'env1';
        insert dfs2;
        System.assert(dfs2.Id != null);

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        User_Story__c userStory = CMTestMethodUtilities.createUserStory('test');
        userStory.Environment__c = env1.Id;
        userStory.Org_Credential__c = testOrg1.Id;
        userStory.Project__c = testProject.Id;
        insert userStory;
        System.assert(userStory.Id != null);

        Test.startTest();

        // Invalid CBM Flow - Main Branch = null
        flowCBM.Main_Branch__c = null;
        update flowCBM;
        GlobalUtilities.deploymentFlowDetails deploymentFlowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        System.assertEquals(true, deploymentFlowDetails.flow.Active__c);
        System.assertEquals(false, deploymentFlowDetails.isCBMFlow);

        // Invalid CBM Flow - Git Repository = null
        flowCBM.Main_Branch__c = 'master';
        flowCBM.Git_Repository__c = null;
        update flowCBM;
        deploymentFlowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        System.assertEquals(true, deploymentFlowDetails.flow.Active__c);
        System.assertEquals(false, deploymentFlowDetails.isCBMFlow);

        // Inactive CBM Flow
        flowCBM.Active__c = false;
        flowCBM.Git_Repository__c = gitRepo.Id;
        update flowCBM;
        deploymentFlowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        System.assertEquals(false, deploymentFlowDetails.flow.Active__c);
        System.assertEquals(true, deploymentFlowDetails.isCBMFlow);

        // Inactive CCM Flow
        testProject.Deployment_Flow__c = flow.Id;
        update testProject;
        deploymentFlowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        System.assertEquals(true, deploymentFlowDetails.flow.Active__c);
        System.assertEquals(false, deploymentFlowDetails.isCBMFlow);

        // Active CCM Flow
        flow.Active__c = false;
        update flow;
        deploymentFlowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStory.Id, '');
        System.assertEquals(false, deploymentFlowDetails.flow.Active__c);
        System.assertEquals(false, deploymentFlowDetails.isCBMFlow);

        Test.stopTest();
    }
    static testMethod void testUserStoriesAheadCalculation() {
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Environment__c envDev1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c envInt = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
        Environment__c envProd = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
        insert new List<Environment__c> {envDev1, envInt, envProd};

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('OrgDev1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envDev1.Id);
        Org__c orgInt = CMTestMethodUtilities.createOrg('OrgInt', 'Sandbox', null, 'SFDC_OrgId3', null, null, system.now(), envInt.Id);
        Org__c orgProd = CMTestMethodUtilities.createOrg('OrgProd', 'Production', null, 'SFDC_OrgId4', null, null, system.now(), envProd.Id);
        insert new List<Org__c> {orgDev1, orgInt, orgProd};

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgDev1.id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgInt.id, Branch__c = 'int');
        Git_Backup__c gitSnapshotProd = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgProd.id, Branch__c = 'master');
        insert new List<Git_Backup__c> {gitSnapshotDev1, gitSnapshotInt, gitSnapshotProd};

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        Deployment_Flow_Step__c stepIntToProd = CMTestMethodUtilities.createFlowStep(envInt.Id, envProd.Id, flowCBM.Id);
        stepIntToProd.Branch__c = 'int';
        insert new List<Deployment_Flow_Step__c> {stepDev1ToInt, stepIntToProd};

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        Git_Org_Commit__c snapshotCommit1 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotDev1.id, Org__c = orgDev1.id, Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c = Date.today().addDays(-5), Commit_Message__c = 'test 1', Status__c = 'Complete'
                                                                 );
        Git_Org_Commit__c snapshotCommit2 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotInt.id, Org__c = orgInt.id, Commit_Id__c = 'b5adccf3937495e8928d1023c5a5c644198b10293', Commit_Date__c = Date.today().addDays(-3), Commit_Message__c = 'test 2', Status__c = 'Complete'
                                                                 );
        Git_Org_Commit__c snapshotCommit3 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotDev1.id, Org__c = orgDev1.id, Commit_Id__c = 'b9adccf3937495e8928d1023c5a5c644198b9876', Commit_Date__c = Date.today().addDays(-1), Commit_Message__c = 'test 3', Status__c = 'Complete'
                                                                 );
        insert new List<Git_Org_Commit__c> {snapshotCommit1, snapshotCommit2, snapshotCommit3};
        Test.setCreatedDate(snapshotCommit1.Id, Datetime.now().addDays(-5));
        Test.setCreatedDate(snapshotCommit2.Id, Datetime.now().addDays(-3));
        Test.setCreatedDate(snapshotCommit3.Id, Datetime.now().addDays(-1));

        System.debug('### START Case 1.');
        // Case 1. Dev1 has 2 user stories with no commits. Both are not ahead.
        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 Dev1');
        userStory1.Org_Credential__c = orgDev1.Id;
        userStory1.Project__c = testProject.Id;
        insert userStory1;

        User_Story__c userStory2 = CMTestMethodUtilities.createUserStory('userStory2 Dev1');
        userStory2.Org_Credential__c = orgDev1.Id;
        userStory2.Project__c = testProject.Id;
        insert userStory2;

        User_Story__c userStory3 = CMTestMethodUtilities.createUserStory('userStory3 Dev1');
        userStory3.Org_Credential__c = orgDev1.Id;
        userStory3.Project__c = testProject.Id;
        insert userStory3;

        System.assertEquals(0, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());

        System.debug('### START Case 2.');
        // Case 2. UserStory1 has 1 'Complete' commit therefore it appears as 'Ahead' in stepDev1ToInt
        User_Story_Commit__c userStoryCommit1 = new User_Story_Commit__c(User_Story__c = userStory1.id, Snapshot_Commit__c = snapshotCommit1.id);
        insert userStoryCommit1;
        Test.setCreatedDate(userStoryCommit1.Id, Datetime.now().addDays(-5));
        userStory1.Promote_Change__c = true;
        update userStory1;
        System.assertEquals(1, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());

        System.debug('### START Case 3.');
        // Case 3. UserStory1 is Promoted to Int. UserStory1 then appears as 'Ahead' in stepIntToProd
        Promotion__c testPromotion1 = CMTestMethodUtilities.createPromotion(testProject.Id, envDev1.Id);
        testPromotion1.Status__c = 'Completed';
        insert testPromotion1;
        Test.setCreatedDate(testPromotion1.Id, Datetime.now().addDays(-4));
        Promoted_User_Story__c promotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion1.Id);
        insert promotedUserstory1;
        Test.setCreatedDate(promotedUserstory1.Id, Datetime.now().addDays(-4));
        userStory1.Org_Credential__c = orgInt.Id;
        userStory1.Environment__c = envInt.Id;
        update userStory1;

        System.assertEquals(1, GlobalUtilities.getUserStoriesAhead(stepIntToProd).size());
        System.assertEquals(0, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());

        System.debug('### START Case 4.');
        // Case 4. UserStory1 gets a commit in Int. UserStory1 still appears as 'Ahead' in stepIntToProd
        User_Story_Commit__c userStoryCommit2 = new User_Story_Commit__c(User_Story__c = userStory1.id, Snapshot_Commit__c = snapshotCommit2.id);
        insert userStoryCommit2;
        Test.setCreatedDate(userStoryCommit2.Id, Datetime.now().addDays(-1));
        List<User_Story__c> listUserStoriesAhead = GlobalUtilities.getUserStoriesAhead(stepIntToProd);
        System.assertEquals(1, listUserStoriesAhead.size());
        // ensure VF required fields are not null
        for(User_Story__c userStoryAhead : listUserStoriesAhead)
            system.assertEquals(userStoryAhead.Org_Credential__r.Org_Type__c, 'Sandbox');

        // Case 5 and 6 are no longer covered with the Ahead/Behind calculation. Support them in the future
        /*
        System.debug('### START Case 5.');
        // Case 5. UserStory1 was returned to Dev1. UserStory1 is not ahead in stepDev1ToInt since the promotion from Dev1 to Int is older than the first commit done in Dev1.
        userStory1.Org_Credential__c = orgDev1.Id;
        userStory1.Environment__c = envDev1.Id;
        update userStory1;
        System.assertEquals(0, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());


        System.debug('### START Case 6.');
        // Case 6. UserStory1 has a new commit in Dev1. UserStory1 is 'Ahead' again in stepDev1ToInt
        User_Story_Commit__c userStoryCommit3 = new User_Story_Commit__c(User_Story__c = userStory1.id, Snapshot_Commit__c = snapshotCommit3.id);
        insert userStoryCommit3;
        System.assertEquals(0, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());
        */

        System.debug('### START Case 5-6 Temporary.');
        // Case 5. UserStory1 was returned to Dev1. UserStory1 is still ahead in stepDev1ToInt
        userStory1.Org_Credential__c = orgDev1.Id;
        userStory1.Environment__c = envDev1.Id;
        update userStory1;
        System.assertEquals(1, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());

        System.debug('### START Case 7.');
        // Case 7. UserStory2 has a Deployment Task only and UserStory3 has an External CI Job only. UserStory2 and UserStory3 are now ahead
        Deployment_Task__c deploymentTask = new Deployment_Task__c(
            Name = 'Manual Task',
            Order__c = 1,
            Type__c = 'Manual Task',
            Status__c = 'Draft',
            User_Story__c = userStory2.Id
        );
        insert deploymentTask;

        External_CI_Setting__c externalCISetting = new External_CI_Setting__c(Name = 'Setting1', CI_Tool__c = 'Jenkins');
        insert externalCISetting;
        External_CI_Job__c externalCIJob = new External_CI_Job__c(Name = 'Job1', User_Story__c = userStory3.Id, External_CI_Setting__c = externalCISetting.Id);
        insert externalCIJob;

        userStory2.Promote_Change__c = true;
        update userStory2;
        userStory3.Promote_Change__c = true;
        update userStory3;

        System.assertEquals(3, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());
    }
    static testMethod void testUserStoriesBehindCalculation() {
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Environment__c envDev1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c envDev2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
        Environment__c envInt = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
        Environment__c envProd = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
        insert new List<Environment__c> {envDev1, envDev2, envInt, envProd};

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('OrgDev1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envDev1.Id);
        Org__c orgDev2 = CMTestMethodUtilities.createOrg('OrgDev2', 'Sandbox', null, 'SFDC_OrgId2', null, null, system.now(), envDev2.Id);
        Org__c orgInt = CMTestMethodUtilities.createOrg('OrgInt', 'Sandbox', null, 'SFDC_OrgId3', null, null, system.now(), envInt.Id);
        Org__c orgProd = CMTestMethodUtilities.createOrg('OrgProd', 'Production', null, 'SFDC_OrgId4', null, null, system.now(), envProd.Id);
        insert new List<Org__c> {orgDev1, orgDev2, orgInt, orgProd};

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgDev1.id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotDev2 = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgDev2.id, Branch__c = 'dev2');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgInt.id, Branch__c = 'int');
        Git_Backup__c gitSnapshotProd = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgProd.id, Branch__c = 'master');
        insert new List<Git_Backup__c> {gitSnapshotDev1, gitSnapshotDev2, gitSnapshotInt, gitSnapshotProd};

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        stepDev1Toint.Destination_Branch__c = 'int';
        Deployment_Flow_Step__c stepDev2ToInt = CMTestMethodUtilities.createFlowStep(envDev2.Id, envInt.Id, flowCBM.Id);
        stepDev2ToInt.Branch__c = 'dev2';
        stepDev2ToInt.Destination_Branch__c = 'int';
        Deployment_Flow_Step__c stepIntToProd = CMTestMethodUtilities.createFlowStep(envInt.Id, envProd.Id, flowCBM.Id);
        stepIntToProd.Branch__c = 'int';
        stepIntToProd.Destination_Branch__c = 'master';
        insert new List<Deployment_Flow_Step__c> {stepDev1ToInt, stepDev2ToInt, stepIntToProd};

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        Git_Org_Commit__c snapshotCommitDev1 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotDev1.Id, Org__c = orgDev1.id, Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c = Date.today().addDays(-5), Commit_Message__c = 'test 1', Status__c = 'Complete'
                                                                    );
        Git_Org_Commit__c snapshotCommitInt1 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotInt.Id, Org__c = orgInt.id, Commit_Id__c = 'b8adccf3937495e8928d1023c5a5c644198b1234', Commit_Date__c = Date.today().addDays(-3), Commit_Message__c = 'test 2', Status__c = 'Complete'
                                                                    );
        Git_Org_Commit__c snapshotCommitInt2 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotInt.Id, Org__c = orgInt.id, Commit_Id__c = 'b9adccf3937495e8928d1023c5a5c644198b9876', Commit_Date__c = Date.today().addDays(-1), Commit_Message__c = 'test 3', Status__c = 'Complete'
                                                                    );
        Git_Org_Commit__c snapshotCommitDev1b = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotDev1.Id, Org__c = orgDev1.id, Commit_Id__c = 'b6adccf3937495e8928d1023c5a5c644198b0694', Commit_Date__c = Date.today(), Commit_Message__c = 'test 4', Status__c = 'Complete'
                                                                     );
        insert new List<Git_Org_Commit__c> {snapshotCommitDev1, snapshotCommitInt1, snapshotCommitInt2, snapshotCommitDev1b};
        Test.setCreatedDate(snapshotCommitDev1.Id, Datetime.now().addDays(-5));
        Test.setCreatedDate(snapshotCommitInt1.Id, Datetime.now().addDays(-3));

        System.debug('### START Case 1');
        // Case 1. No user stories behind in Dev1
        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 Dev1');
        userStory1.Org_Credential__c = orgDev1.Id;
        userStory1.Project__c = testProject.Id;
        insert userStory1;

        User_Story_Commit__c userStoryCommitDev1 = new User_Story_Commit__c(User_Story__c = userStory1.id, Snapshot_Commit__c = snapshotCommitDev1.id);
        insert userStoryCommitDev1;
        Test.setCreatedDate(userStoryCommitDev1.Id, Datetime.now().addDays(-5));

        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepDev1ToInt).size());

        System.debug('### START Case 2');
        // Case 2. UserStory1 is Promoted to Int. UserStory1 appears as 'Behind' in stepDev2ToInt
        Promotion__c testPromotion1 = CMTestMethodUtilities.createPromotion(testProject.Id, envDev1.Id);
        testPromotion1.Status__c = 'Completed';
        insert testPromotion1;
        Test.setCreatedDate(testPromotion1.Id, Datetime.now().addDays(-4));

        Promoted_User_Story__c promotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion1.Id);
        insert promotedUserstory1;
        Test.setCreatedDate(promotedUserStory1.Id, Datetime.now().addDays(-4));

        userStory1.Org_Credential__c = orgInt.Id;
        userStory1.Environment__c = envInt.Id;
        update userStory1;

        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        System.debug('*** START Case 3');
        // UserStory1 does not appear as 'Behind' in stepDev1ToInt
        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepDev1ToInt).size());
        System.assertEquals(0, GlobalUtilities.getUserStoriesAhead(stepIntToProd).size()); 
        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        System.debug('### START Case 5');
        // UserStory1 is Promoted to Production. UserStory1 still appears as 'Behind' in stepDev2ToInt
        Promotion__c testPromotion2 = CMTestMethodUtilities.createPromotion(testProject.Id, envInt.Id);
        testPromotion2.Status__c = 'Completed';
        insert testPromotion2;
        Test.setCreatedDate(testPromotion2.Id, Datetime.now().addDays(-2));

        Promoted_User_Story__c promotedUserStory1b = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotion2.Id);
        insert promotedUserstory1b;
        Test.setCreatedDate(promotedUserStory1b.Id, Datetime.now().addDays(-2));
        Test.startTest();
        userStory1.Org_Credential__c = orgProd.Id;
        userStory1.Environment__c = envProd.Id;
        update userStory1;

        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        System.debug('### START Case 6');
        // Back Promote UserStory1 to Dev2. StepDev2ToInt will not have 'Behind' userStories
        Promotion__c testBackPromotion1 = CMTestMethodUtilities.createBackPromotion(testProject.Id, envDev2.Id);
        testBackPromotion1.Status__c = 'Completed';
        testBackPromotion1.Source_Environment__c = envInt.Id;
        testBackPromotion1.Source_Org_Credential__c = orgInt.Id;
        insert testBackPromotion1;
        Promoted_User_Story__c backPromotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testBackPromotion1.Id);
        insert backPromotedUserstory1;
        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        System.debug('### START Case 7');
        // UserStory1 was returned to Dev1 and Recommitted. UserStory1 is 'Ahead' again in stepDev1ToInt
        userStory1.Org_Credential__c = orgDev1.Id;
        userStory1.Environment__c = envDev1.Id;
        update userStory1;

        User_Story_Commit__c userStoryCommitDev1b = new User_Story_Commit__c(User_Story__c = userStory1.id, Snapshot_Commit__c = snapshotCommitDev1b.id);
        insert userStoryCommitDev1b;

        System.assertEquals(0, GlobalUtilities.getUserStoriesAhead(stepDev1ToInt).size());
        Test.stopTest();
    }
    static testMethod void testUserStoriesBehindUncommonPathCalculation() {
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Environment__c envDev1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c envDev2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
        Environment__c envInt = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
        Environment__c envProd = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
        insert new List<Environment__c> {envDev1, envDev2, envInt, envProd};

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('OrgDev1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envDev1.Id);
        Org__c orgDev2 = CMTestMethodUtilities.createOrg('OrgDev2', 'Sandbox', null, 'SFDC_OrgId2', null, null, system.now(), envDev2.Id);
        Org__c orgInt = CMTestMethodUtilities.createOrg('OrgInt', 'Sandbox', null, 'SFDC_OrgId3', null, null, system.now(), envInt.Id);
        Org__c orgProd = CMTestMethodUtilities.createOrg('OrgProd', 'Production', null, 'SFDC_OrgId4', null, null, system.now(), envProd.Id);
        insert new List<Org__c> {orgDev1, orgDev2, orgInt, orgProd};

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgDev1.id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotDev2 = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgDev2.id, Branch__c = 'dev2');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgInt.id, Branch__c = 'int');
        Git_Backup__c gitSnapshotProd = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgProd.id, Branch__c = 'master');
        insert new List<Git_Backup__c> {gitSnapshotDev1, gitSnapshotDev2, gitSnapshotInt, gitSnapshotProd};

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        stepDev1Toint.Destination_Branch__c = 'int';
        Deployment_Flow_Step__c stepDev2ToInt = CMTestMethodUtilities.createFlowStep(envDev2.Id, envInt.Id, flowCBM.Id);
        stepDev2ToInt.Branch__c = 'dev2';
        stepDev2ToInt.Destination_Branch__c = 'int';
        Deployment_Flow_Step__c stepIntToProd = CMTestMethodUtilities.createFlowStep(envInt.Id, envProd.Id, flowCBM.Id);
        stepIntToProd.Branch__c = 'int';
        stepIntToProd.Destination_Branch__c = 'master';
        insert new List<Deployment_Flow_Step__c> {stepDev1ToInt, stepDev2ToInt, stepIntToProd};

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        Git_Org_Commit__c snapshotCommitInt1 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotInt.Id, Org__c = orgInt.id, Commit_Id__c = 'b8adccf3937495e8928d1023c5a5c644198b1234', Commit_Date__c = Date.today().addDays(-5), Commit_Message__c = 'test 2', Status__c = 'Complete'
                                                                    );
        Git_Org_Commit__c snapshotCommitInt2 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotInt.Id, Org__c = orgInt.id, Commit_Id__c = 'b9adccf3937495e8928d1023c5a5c644198b9876', Commit_Date__c = Date.today().addDays(-2), Commit_Message__c = 'test 2', Status__c = 'Complete'
                                                                    );
        Git_Org_Commit__c snapshotCommitProd = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotProd.Id, Org__c = orgProd.id, Commit_Id__c = 'b6adccf3937495e8928d1023c5a5c644198b23423', Commit_Date__c = Date.today(), Commit_Message__c = 'test 3', Status__c = 'Complete'
                                                                    );
        insert new List<Git_Org_Commit__c> {snapshotCommitInt1, snapshotCommitInt2, snapshotCommitProd};

        Test.setCreatedDate(snapshotCommitInt1.Id, Datetime.now().addDays(-5));
        Test.setCreatedDate(snapshotCommitInt2.Id, Datetime.now().addDays(-2));
        Test.setCreatedDate(snapshotCommitProd.Id, Datetime.now().addDays(-1));

        System.debug('### START Case 1');
        // Case 1. UserStory1 is created directly in Int. After the UserStory2 has a commit, it appears as 'Behind' in both Dev1 and Dev2
        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory2 Int');
        userStory1.Org_Credential__c = orgInt.Id;
        userStory1.Project__c = testProject.Id;
        insert userStory1;

        User_Story_Commit__c userStoryCommitInt1 = new User_Story_Commit__c(User_Story__c = userStory1.Id, Snapshot_Commit__c = snapshotCommitInt1.id);
        insert userStoryCommitInt1;
        Test.setCreatedDate(userStoryCommitInt1.Id, Datetime.now().addDays(-5));

        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev1ToInt).size()); // UserStory2 is 'Behind' to Dev1
        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size()); // UserStory2 are 'Behind' to Dev2

        System.debug('### START Case 2');
        // UserStory1 is promoted to Prod. It still appears as 'Behind' in Dev1 and Dev2
        Promotion__c testPromotionInt1 = CMTestMethodUtilities.createPromotion(testProject.Id, envInt.Id);
        testPromotionInt1.Status__c = 'Completed';
        insert testPromotionInt1;
        Test.setCreatedDate(testPromotionInt1.Id, Datetime.now().addDays(-4));

        Promoted_User_Story__c promotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testPromotionInt1.Id);
        insert promotedUserstory1;
        Test.setCreatedDate(promotedUserstory1.Id, Datetime.now().addDays(-4));

        userStory1.Org_Credential__c = orgProd.Id;
        userStory1.Environment__c = envProd.Id;
        update userStory1;

        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev1ToInt).size()); // UserStory2 is 'Behind' to Dev1
        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size()); // UserStory2 are 'Behind' to Dev2

        System.debug('### START Case 3');
        // UserStory1 is back promoted to Dev1. UserStory is no longer 'Behind' in Dev1
        Promotion__c testBackPromotion1 = CMTestMethodUtilities.createBackPromotion(testProject.Id, envDev1.Id);
        testBackPromotion1.Status__c = 'Completed';
        testBackPromotion1.Source_Environment__c = envInt.Id;
        testBackPromotion1.Source_Org_Credential__c = orgInt.Id;
        insert testBackPromotion1;
        Test.setCreatedDate(testBackPromotion1.Id, Datetime.now().addDays(-3));

        Promoted_User_Story__c backPromotedUserStory1 = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testBackPromotion1.Id);
        insert backPromotedUserstory1;
        Test.setCreatedDate(backPromotedUserstory1.Id, Datetime.now().addDays(-3));

        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepDev1ToInt).size());
        System.assertEquals(1, GlobalUtilities.getUserStoriesBehind(stepDev2ToInt).size());

        System.debug('### START Case 4');
        // UserStory1 recieves a commit in Prod. It is now 'Behind' in Int.
        User_Story_Commit__c userStoryCommitProd = new User_Story_Commit__c(User_Story__c = userStory1.Id, Snapshot_Commit__c = snapshotCommitProd.id);
        insert userStoryCommitProd;
        Test.setCreatedDate(userStoryCommitProd.Id, Datetime.now().addDays(-1));
        Test.startTest();
        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepIntToProd).size());

        System.debug('### START Case 5');
        // UserStory1 is back promoted to Int. It is now 'Behind' again in Dev1, even though it was back promoted before.
        Promotion__c testBackPromotion2 = CMTestMethodUtilities.createBackPromotion(testProject.Id, envInt.Id);
        testBackPromotion2.Status__c = 'Completed';
        testBackPromotion2.Source_Environment__c = envProd.Id;
        testBackPromotion2.Source_Org_Credential__c = orgProd.Id;
        insert testBackPromotion2;

        Promoted_User_Story__c backPromotedUserStory1b = new Promoted_User_Story__c(User_Story__c = userStory1.Id, Promotion__c = testBackPromotion2.Id);
        insert backPromotedUserstory1b;

        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepIntToProd).size());
        System.assertEquals(0, GlobalUtilities.getUserStoriesBehind(stepDev1ToInt).size());
        Test.stopTest();
    }
    static testMethod void testUserStoriesBehindNoCommitsCalculation() {
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Environment__c envDev1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c envDev2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
        Environment__c envInt = new Environment__c(Name = 'Integration Environment', Type__c = 'Sandbox');
        Environment__c envProd = new Environment__c(Name = 'Production Environment', Type__c = 'Production');
        insert new List<Environment__c> {envDev1, envDev2, envInt, envProd};

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('OrgDev1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), envDev1.Id);
        Org__c orgDev2 = CMTestMethodUtilities.createOrg('OrgDev2', 'Sandbox', null, 'SFDC_OrgId2', null, null, system.now(), envDev2.Id);
        Org__c orgInt = CMTestMethodUtilities.createOrg('OrgInt', 'Sandbox', null, 'SFDC_OrgId3', null, null, system.now(), envInt.Id);
        Org__c orgProd = CMTestMethodUtilities.createOrg('OrgProd', 'Production', null, 'SFDC_OrgId4', null, null, system.now(), envProd.Id);
        insert new List<Org__c> {orgDev1, orgDev2, orgInt, orgProd};

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgDev1.id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotDev2 = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgDev2.id, Branch__c = 'dev2');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgInt.id, Branch__c = 'int');
        Git_Backup__c gitSnapshotProd = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgProd.id, Branch__c = 'master');
        insert new List<Git_Backup__c> {gitSnapshotDev1, gitSnapshotDev2, gitSnapshotInt, gitSnapshotProd};

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        stepDev1Toint.Destination_Branch__c = 'int';
        Deployment_Flow_Step__c stepDev2ToInt = CMTestMethodUtilities.createFlowStep(envDev2.Id, envInt.Id, flowCBM.Id);
        stepDev2ToInt.Branch__c = 'dev2';
        stepDev2ToInt.Destination_Branch__c = 'int';
        Deployment_Flow_Step__c stepIntToProd = CMTestMethodUtilities.createFlowStep(envInt.Id, envProd.Id, flowCBM.Id);
        stepIntToProd.Branch__c = 'int';
        stepIntToProd.Destination_Branch__c = 'master';
        insert new List<Deployment_Flow_Step__c> {stepDev1ToInt, stepDev2ToInt, stepIntToProd};

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        User_Story__c userStory1 = CMTestMethodUtilities.createUserStory('userStory1 Dev2');
        userStory1.Org_Credential__c = orgDev2.Id;
        userStory1.Project__c = testProject.Id;
        insert userStory1;

        // UserStory2 has a Deployment Task only and UserStory3 has an External CI Job only. UserStory2 and UserStory3 are promoted to Int. Then they are Behind in Dev2
        User_Story__c userStory2 = CMTestMethodUtilities.createUserStory('userStory2 Dev1');
        userStory2.Org_Credential__c = orgDev1.Id;
        userStory2.Project__c = testProject.Id;
        insert userStory2;

        User_Story__c userStory3 = CMTestMethodUtilities.createUserStory('userStory3 Dev1');
        userStory3.Org_Credential__c = orgDev1.Id;
        userStory3.Project__c = testProject.Id;
        insert userStory3;

        Deployment_Task__c deploymentTask = new Deployment_Task__c(
            Name = 'Manual Task',
            Order__c = 1,
            Type__c = 'Manual Task',
            Status__c = 'Draft',
            User_Story__c = userStory2.Id
        );
        insert deploymentTask;

        External_CI_Setting__c externalCISetting = new External_CI_Setting__c(Name = 'Setting1', CI_Tool__c = 'Jenkins');
        insert externalCISetting;
        External_CI_Job__c externalCIJob = new External_CI_Job__c(Name = 'Job1', User_Story__c = userStory3.Id, External_CI_Setting__c = externalCISetting.Id);
        insert externalCIJob;

        Promotion__c testPromotionDev1 = CMTestMethodUtilities.createPromotion(testProject.Id, envDev1.Id);
        testPromotionDev1.Status__c = 'Completed';
        insert testPromotionDev1;
        Test.setCreatedDate(testPromotionDev1.Id, Datetime.now().addDays(-2));

        Promoted_User_Story__c promotedUserStory2 = new Promoted_User_Story__c(User_Story__c = userStory2.Id, Promotion__c = testPromotionDev1.Id);
        insert promotedUserstory2;
        Test.setCreatedDate(promotedUserstory2.Id, Datetime.now().addDays(-2));

        Promoted_User_Story__c promotedUserStory3 = new Promoted_User_Story__c(User_Story__c = userStory3.Id, Promotion__c = testPromotionDev1.Id);
        insert promotedUserstory3;
        Test.setCreatedDate(promotedUserstory3.Id, Datetime.now().addDays(-2));

        List<User_Story__c> listUserStoriesBehind = GlobalUtilities.getUserStoriesBehind(stepDev2ToInt);
        System.assertEquals(2, listUserStoriesBehind.size()); // UserStory2 and UserStory3 are 'Behind' to Dev2
        // ensure VF required fields are not null
        for(User_Story__c userStoryBehind : listUserStoriesBehind)
            system.assertEquals(userStoryBehind.Org_Credential__r.Org_Type__c, 'Sandbox');

        UserStoryExt ext1 = new UserStoryExt(new ApexPages.StandardController(userStory1));
        System.assertEquals(2, ext1.userStoriesBehind.size());
    }

    static testMethod void testUserStoryDependency() {
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        insert env1;
        Environment__c env2 = new Environment__c(Name = 'Integration Environment', Type__c = 'Production');
        insert env2;
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        testOrg1.Default_Credential__c = true;
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Sandbox', null, 'SFDC_OrgId_2', null, null, system.now(), env2.Id);
        testOrg2.Default_Credential__c = true;
        insert testOrg2;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;
        User_Story__c userStory = CMTestMethodUtilities.createUserStory('test');
        userStory.Environment__c = env1.Id;
        userStory.Org_Credential__c = testOrg1.Id;
        userStory.Project__c = testProject.Id;
        insert userStory;
        User_Story__c userStory2 = CMTestMethodUtilities.createUserStory('testnotDependency');
        userStory2.Environment__c = env1.Id;
        userStory2.Org_Credential__c = testOrg1.Id;
        userStory2.Project__c = testProject.Id;
        insert userStory2;
        User_Story__c userStory3 = CMTestMethodUtilities.createUserStory('testDependency');
        userStory3.Environment__c = env2.Id;
        userStory3.Org_Credential__c = testOrg2.Id;
        userStory3.Project__c = testProject.Id;
        insert userStory3;
        Team_Dependency__c td = new Team_Dependency__c();
        td.Provider_User_Story__c = userStory2.Id;
        td.Dependent_User_Story__c =  userStory.Id;
        insert td;
        Team_Dependency__c td2 = new Team_Dependency__c();
        td2.Provider_User_Story__c = userStory3.Id;
        td2.Dependent_User_Story__c =  userStory.Id;
        insert td2;

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        insert new List<Deployment_Flow_Step__c> {stepDev1ToInt};

        Promotion__c testPromotion1 = CMTestMethodUtilities.createPromotion(testProject.Id, env2.Id);
        testPromotion1.Status__c = 'Completed';
        testPromotion1.Source_Environment__c = env2.Id;
        testPromotion1.Destination_Environment__c = env1.Id;
        testPromotion1.Back_Promotion__c = true;
        insert testPromotion1;
        Promoted_User_Story__c pusBack = new Promoted_User_Story__c(User_Story__c = userStory2.Id, Promotion__c = testPromotion1.Id);
        insert pusBack;

        list<User_Story__c> usDep = GlobalUtilities.getUserStoriesDependencies(new set<Id> {userStory.Id}, env1.Id);
        //there are two dependencies to US1 but US3 has been taken back in a time to US1
        system.assertEquals(usDep.size(), 1);

        // ensure VF required fields are not null
        User_Story__c userStory4 =  GlobalUtilities.getUserStoryById(userStory3.Id);
        system.assertEquals(userStory4.Org_Credential__r.Org_Type__c, 'Sandbox');
    }
}