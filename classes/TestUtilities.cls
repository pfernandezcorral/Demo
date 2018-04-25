@isTest
public class TestUtilities {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    @testSetup static void setupTestDataDML(){
        testMethodUtilities.upsertOrgwideSettings();
    }
    public static String getTestNameSpace() {
        if ([select id, name, namespacePrefix from apexclass where name = 'CopadoSetupController' and namespaceprefix = 'copado'].size() == 1)
            return 'copado__';
        return 'none';
    }
    public static void setTestSettingsEE(){
        enableLicenses(1,0,0,0,0,0);
    }
    public static Settings__c getTestSettings() {
        Blob key = Crypto.generateAesKey(256);
        Settings__c s = new Settings__c(Namespace__c = getTestNameSpace(), server_url__c = 'test.com', Enabled_Multi_Licenses__c = false, CryptoKEY__c = EncodingUtil.base64Encode(key));
        return s;
    }
    public static void getTestSettingsMultilicense() {
        enableLicenses(1,1,0,0,0,0);
    }
    public static void getAllMultilicense() {
        enableLicenses(10,10,10,10,10,10);
    }
    public static void enableLicenses(Integer copado, Integer ccm, Integer cst) {
        enableLicenses(copado, ccm, cst, 0,0,0);
    }
    public static void enableLicenses(Integer copado, Integer ccm, Integer cst, Integer cad, Integer cch) {
        enableLicenses(copado, ccm, cst, cad, cch, 0);
    }
    public static void enableLicenses(Integer copado, Integer ccm, Integer cst, Integer cad, Integer cch, Integer cbmBranches) {
        FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled',copado);
        FeatureManagement.setPackageIntegerValue('CCM_Licenses_Enabled', ccm);
        FeatureManagement.setPackageIntegerValue('CST_Licenses_Enabled', cst);
        FeatureManagement.setPackageIntegerValue('CAD_Licenses_Enabled',cad);
        FeatureManagement.setPackageIntegerValue('CCH_Licenses_Enabled', cch);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', cbmBranches);
    }
    public static void exceedCopadoLicenses() {
        LicenseManagerController con = new LicenseManagerController();

        String copadoLicenses = '2';
        String ccmLicenses = '2';
        String cstLicenses = '2';
        String cadLicenses = '2';
        String cchLicenses = '2';
        String multiLicenses = 'true';
        String b = '{"customerOrg":{"Name":"Copado Development Org","orgId":"00D24000000aZrZEAU","autoRecharge":false,"credits":99818,"userId":"005240000012JyBAAU","copadoLicenses":' + copadoLicenses + ',"ccmLicenses":' + ccmLicenses + ',"cstLicenses":' + cstLicenses + ',"cadLicenses":' + cadLicenses + ',"multiLicenses":' + multiLicenses + ',"id":73011},"userInfo":{"accessibilityMode__is_set":true}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        insertAdminUsers(new List<String> {'user1-TestUtilities@test-copado.org', 'user2-TestUtilities@test-copado.org'});
        List<User> users = [Select Id, Name From User Where Username = 'user1-TestUtilities@test-copado.org' OR Username = 'user2-TestUtilities@test-copado.org' Limit 2];
        System.debug(users);
        if (users.size() == 2) {

            // Add User1 as Copado
            con.dummyUser.ManagerId = users[0].Id;
            con.assignCopado = true;
            con.assignCCM = false;
            con.assignCST = true;
            con.assignCAD = false;
            con.assignCCH = false;
            con.addUser();

            // Add User1 as Copado
            con.dummyUser.ManagerId = users[1].Id;
            con.assignCopado = true;
            con.assignCCM = true;
            con.addUser();

            // Exceed the Copado Licenses by reducing the available licenses to 1.
            //CANNOT UPDATE PROVISIONING
            //enableLicenses(1, 2, 2, 2, 2);
        }
    }
    public static void assignLicense(String username, Boolean copadoEnabled, Boolean ccmEnabled, Boolean cstEnabled) {
        User u = [SELECT Id FROM User WHERE username = :username];
        Copado_License__c license = new Copado_License__c();
        license.Enable_Copado__c = copadoEnabled;
        license.Enable_CCM__c = ccmEnabled;
        license.Enable_CST__c = cstEnabled;
        license.SetupOwnerId = u.Id;
        Utilities.Secure_DML(license, Utilities.DML_Action.UPS, schema.Sobjecttype.Copado_License__c);
    }
    public static void assignLicense(String username, Boolean copadoEnabled, Boolean ccmEnabled, Boolean cstEnabled, Boolean cadEnabled, Boolean cchEnabled) {
        User u = [SELECT Id FROM User WHERE username = :username];
        Copado_License__c license = Copado_License__c.getInstance(u.Id);
        license.Enable_Copado__c = copadoEnabled;
        license.Enable_CCM__c = ccmEnabled;
        license.Enable_CST__c = cstEnabled;
        license.Enable_CAD__c = cadEnabled;
        license.Enable_CCH__c = cchEnabled;
        Utilities.Secure_DML(license, Utilities.DML_Action.UPS, schema.Sobjecttype.Copado_License__c);
    }
    public static void insertUser(String username, String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        User futureUser = new User(firstname = 'Future', lastname = 'User',
                                   alias = 'future',
                                   email = 'test@test.org',
                                   emailencodingkey = 'UTF-8',
                                   languagelocalekey = 'en_US',
                                   localesidkey = 'en_US',
                                   profileid = p.Id,
                                   timezonesidkey = 'America/Los_Angeles',
                                   username = username
                                  );
        Utilities.Secure_DML(futureUser, Utilities.DML_Action.UPS, schema.Sobjecttype.USer);
    }
    public static void insertAdminUsers(List<String> usernames) {
        List<User> users = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        for (String username : usernames) {
            User futureUser = new User(firstname = 'Future', lastname = 'User',
                                       alias = 'future',
                                       email = 'test@test.org',
                                       emailencodingkey = 'UTF-8',
                                       languagelocalekey = 'en_US',
                                       localesidkey = 'en_US',
                                       profileid = p.Id,
                                       timezonesidkey = 'America/Los_Angeles',
                                       username = username
                                      );
            users.add(futureUser);
        }
        Utilities.Secure_DML(users, Utilities.DML_Action.UPS, schema.Sobjecttype.USer);
    }
    static testMethod void runAllTests() {
        Org__c testFromOrg = testMethodUtilities.create('a', 'b', 'c', 'd', 'e', 'f', System.now());
        insert testFromOrg;
        Deployment__c testDeployment = testMethodUtilities.create('a', System.now(), System.now(), testFromOrg.Id, 'c', 'd');
        insert testDeployment;
        Step__c testStep = testMethodUtilities.create('a', 'b', 'c', testDeployment.Id, 0, 'e', 'f');
        insert testStep;
        Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id, 'b', testFromOrg.Id);
        insert testDestOrg;
        Deployment_Job__c testJob = testMethodUtilities.create(0, testDestOrg.Id, 'b', 'c', testStep.Id);
        insert testJob;

        Test.startTest();
        Utilities con = new Utilities();
        Utilities.resetStatuses(testDeployment.Id, true);
        system.assertEquals('Not started', Utilities.getStepsByDeploymentId(testDeployment.Id)[0].Status__c);
        system.assertEquals('Pending', [Select Id, Status__c, Step__r.Deployment__c from Deployment_Job__c where Step__r.Deployment__c = :testDeployment.Id ][0].Status__c);
        system.assertEquals('Pending', [Select Id, Early_Completion_Status__c, Step__r.Deployment__c from Deployment_Job__c where Step__r.Deployment__c = :testDeployment.Id ][0].Early_Completion_Status__c);

        String strFields = Utilities.describeFields('WRONGOBJECT');
        system.assertEquals(null, strFields);
        strFields = Utilities.describeFields('Account');
        system.debug(strFields);
        system.assert(strFields.contains('Name'));
        Blob myBlob = Blob.valueof(strFields);
        Utilities.insertAttachment(myBlob, 'att name', 'text', testDeployment.Id);

        boolean isValid = false;
        Org__c[] allorgs = Utilities.getAllOrgs();
        for (Org__c o : Utilities.getAllOrgs()) { if (o.Id == testFromOrg.Id)isValid = true; }
        system.assert(isValid);

        Org__c org = Utilities.getOrgById(testFromOrg.Id);
        system.assert(org != null);

        Deployment__c dep = Utilities.getDeploymentById(testDeployment.Id);
        system.assert(dep != null);

        isValid = false;
        for (Step__c s : Utilities.getStepsByDeploymentId(testDeployment.Id)) { if (s.Id == testStep.Id)isValid = true; }
        system.assert(isValid);

        Step__c s = Utilities.getStepById(testStep.Id);
        system.assert(s != null);

        isValid = false;
        for (Destination_Org__c x : Utilities.getDestinationOrgsByDeploymentId(testDeployment.Id)) { if (x.Id == testDestOrg.Id)isValid = true; }
        system.assert(isValid);

        Destination_Org__c dest = Utilities.getDestinationOrgsById(testDestOrg.Id);
        system.assert(dest != null);

        con.httpGet('www.herokuUrl.com/forCopado');
        for (Integer i = 0; i < 20; i++) {
            System.assert(Utilities.randomInteger(0, 4) <= 4);
            System.assert(Utilities.randomInteger(0, 4) >= 0);
        }
        for (Integer i = 0; i < 100; i++) {
            System.assert(Utilities.randomInteger(0, 59) <= 59);
            System.assert(Utilities.randomInteger(0, 59) >= 0);
        }

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'test');
        insert gitRepo;
        System.assertNotEquals(null, gitRepo.Id);
        System.assertEquals(gitRepo.Id, Utilities.getGitById(gitRepo.Id).Id);
        update gitRepo;
        upsert gitRepo;
        delete gitRepo;

        Release__c release = new Release__c(Name = 'Winter Release');
        insert release;
        System.assertEquals(release.Id, Utilities.getReleaseById(release.Id).Id);

        Environment__c env1 = new Environment__c(Name = 'UAT Environment', Type__c = 'Production');
        insert env1;
        Environment__c env2 = new Environment__c(Name = 'PROD Environment', Type__c = 'Production');
        insert env2;
        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        insert testOrg1;
        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', null, 'SFDC_OrgId2', null, null, system.now(), env2.Id);
        insert testOrg2;
        Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
        insert flow;
        Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
        insert dfs;
        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flow.Id;
        insert testProject;
        Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(testProject.Id, env1.Id);
        insert testPromotion;
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        insert testUserStory;

        Promotion__c promotion = Utilities.getPromotionById(testPromotion.Id);
        System.assert(promotion != null);

        User_Story__c userStory = Utilities.getUserStoryById(testUserStory.Id);
        System.assert(userStory != null);

        Utilities.sendEmail('test@test.com', 'test', 'test');
        Utilities.getPicklistValues(Settings.ns + 'User_Story__c', Settings.ns + 'Status__c');
        Utilities.isChatterEnabled(Settings.ns + 'Deployment__c');
        Utilities.getClassicSessionId();

        //Test Secure DMLs missing
        Org__c testOrgDMLs = new Org__c(Name = 'Test Secure DMLs Org',SFDC_Org_ID__c = 'FAKEORGIDTESTDML');
        insert testOrgDMLs;
        Utilities.Secure_DML(testOrgDMLs, Utilities.DML_Action.DEL, schema.Sobjecttype.Org__c);

        External_CI_Setting__c externalCISetting = new External_CI_Setting__c(Name='Jenkins Test', CI_Tool__c='Jenkins');
        insert externalCISetting;
        System.assertEquals(externalCISetting.Id, Utilities.getCISettingById(externalCISetting.Id).Id);

        External_CI_Job__c externalCIJob = new External_CI_Job__c(Name='Jenkins Test', External_CI_Setting__c=externalCISetting.Id);
        insert externalCIJob;
        System.assertEquals(externalCIJob.Id, Utilities.getCIJobById(externalCIJob.Id).Id);

        gitRepo = new Git_Repository__c(name = 'test');
        insert gitRepo;
        testOrgDMLs = new Org__c(Name = 'Test Secure DMLs Org',SFDC_Org_ID__c = 'FAKEORGIDTESTDML');
        insert testOrgDMLs;
        Git_Backup__c snap = new Git_Backup__c(Name='TestUtils Test', Git_Repository__c=gitRepo.Id, Org__c=testOrgDMLs.Id);
        insert snap;
        System.assertEquals(snap.Id, Utilities.getGitBackupById(snap.Id).Id);

        External_CI_Setting__c externalCISetting2 = new External_CI_Setting__c(Name = 'Setting1', CI_Tool__c = 'Jenkins');
        insert externalCISetting2;
        External_CI_Job__c externalCIJob2 = new External_CI_Job__c(Name = 'Job1', User_Story__c = testUserStory.Id, External_CI_Setting__c = externalCISetting2.Id);
        insert externalCIJob2;
        External_CI_Job__c eCIjob2 = Utilities.getCIJobById(externalCIJob2.Id);
        System.assert(eCIjob2 != null);
        Deployment_Flow__c df2 = Utilities.getDeploymentFlowById(flow.Id);
        System.assert(df2 != null);

        String sId = Utilities.getClassicSessionId();
        System.assert(sId != null);

        Test.stopTest();
    }

    public static void createAllDXTestData() {
        List<Environment__c> envList = new List<Environment__c>();
        Environment__c env1 = new Environment__c();
        env1.Name = 'Scratch Org';
        envList.add(env1);
        Environment__c env2 = new Environment__c();
        env2.Name = 'Dev Hub';
        envList.add(env2);
        Environment__c env3 = new Environment__c();
        env3.Name = 'Scratch Org 1';
        envList.add(env3);
        insert envList;

        List<Org__c> orgCredentialList = new List<Org__c>();
        Org__c org = testMethodUtilities.create('Scratch Org 1', 'Scratch Org', 'password123', 'orgId', 'token', 'test@test.com', System.now());
        org.Environment__c = env1.Id;
        orgCredentialList.add(org);
        Org__c sOrg = testMethodUtilities.create('Scratch Org 2 For Branch', 'Scratch Org', 'password132', 'org23Id', 'token23', 'test23@test23.com', System.now());
        sOrg.Environment__c = env1.Id;
        orgCredentialList.add(sOrg);
        Org__c s1Org = testMethodUtilities.create('Scratch Org 2 For Org', 'Scratch Org', 'password152', 'org25Id', 'token25', 'test25@test25.com', System.now());
        s1Org.Environment__c = env1.Id;
        orgCredentialList.add(s1Org);
        Org__c orgBranch = testMethodUtilities.create('Scratch Org Branch', 'Scratch Org Branch', 'password098', 'orgId12', 'token12', 'test12@test12.com', System.now());
        orgBranch.Environment__c = env1.Id;
        orgCredentialList.add(orgBranch);
        Org__c orgBranch1 = testMethodUtilities.create('Scratch Org Branch 1', 'Scratch Org', 'password987', 'orgId123', 'token123', 'test123@test123.com', System.now());
        orgBranch1.Environment__c = env1.Id;
        orgCredentialList.add(orgBranch1);
        Org__c org1 = testMethodUtilities.create('Dev Hub 1', 'Production/Developer', 'password234', 'orgId1', 'token1', 'test1@test1.com', System.now());
        org1.is_Developer_Hub_Org__c = true;
        org1.Environment__c = env2.Id;
        orgCredentialList.add(org1);
        insert orgCredentialList;

        Git_Repository__c gitRepo = testMethodUtilities.create('git 1','test un','test pw','https://git.com');
        insert gitRepo;

        Git_Backup__c gitSnapcshot = testMethodUtilities.create('my first git snapshot', 'master', '', gitRepo, Date.today(), org);
        insert gitSnapcshot;

        List<Artifact__c> artifactList = new List<Artifact__c>();
        Artifact__c art = new Artifact__c();
        art.Name = 'StaticResources';
        art.Org_Credential__c = org.Id;
        artifactList.add(art);

        Artifact__c art1 = new Artifact__c();
        art1.Name = 'StaticResources2';
        art1.Org_Credential__c = org1.Id;
        art1.Artifact_Repository__c = gitRepo.Id;
        artifactList.add(art1);
        insert artifactList;

        List<Attachment> attachmentList = new List<Attachment>();
        Attachment att = new Attachment();
        att.Body = Blob.valueOf('{"selectedArtifactIDs" : [ "' + art.Id + '" ],"metadataSourceType" : "artifact","metadataSource" : "' + art.Id + '"}');
        att.Name = 'metadataSources.json';
        att.ParentId = org.Id;
        attachmentList.add(att);

        Attachment att1 = new Attachment();
        att1.Body = Blob.valueOf('{"selectedArtifactIDs" : [ "123456789012345678" ],"metadataSourceType" : "branch","metadataSource" : "123456789012345678"}');
        att1.Name = 'metadataSources.json';
        att1.ParentId = orgBranch1.Id;
        attachmentList.add(att1);

        Attachment att2 = new Attachment();
        att2.Body = Blob.valueOf('{"username":"test-qqqnyhaskzxn@example.com","accessToken":"00D5E0000000sg3!ARgAQMa4MbUzMRzR7LnXQ1e6iLe1YjQIGvtgRnylltDmcQSk7B1L2mMBTLDpqu96ICgJCnHoJFynRXKQ2nUIM2VQuzo0sjT9","instanceUrl":"https://ruby-efficiency-5897-dev-ed.cs84.my.salesforce.com","expirationDate":"2018-03-13","devHubId":"my@copado.devhub","id":"00D5E0000000sg3UAA","createdBy":"my@copado.devhub","createdDate":"2018-03-06T10:55:37.000+0000","status":"Active","edition":"Developer","orgName":"FO 6 mart","alias":"a0T0Y0000035dqP"}');
        att2.Name = 'OrgDetails';
        att2.ParentId = orgBranch1.Id;
        attachmentList.add(att2);

        Attachment att3 = new Attachment();
        att3.Body = Blob.valueOf('{"password":"1G!f8x6Is("}');
        att3.Name = 'IdeDetails';
        att3.ParentId = orgBranch1.Id;
        attachmentList.add(att3);

        Attachment att4 = new Attachment();
        att4.Body = Blob.valueOf('');
        att4.Name = 'DxLoadMetadataError';
        att4.ParentId = orgBranch1.Id;
        attachmentList.add(att4);
        insert attachmentList;

        Scratch_Org_Definition__c sod = new Scratch_Org_Definition__c();
        sod.Name = 'Scratch Org Definition';
        sod.Scratch_Org_Definition_JSON__c = '{"username" : null,"orgPreferences" : {"enabled" : [ "AsyncSaveEnabled", "ChatterEnabled", "DisableParallelApexTesting", "EnhancedEmailEnabled", "EventLogWaveIntegEnabled","LoginForensicsEnabled" ],"disabled" : [ "AnalyticsSharingEnable" ]},"orgName" : null,"language" : "de","hasSampleData" : false,"features" : ["Communities", "ContractApprovals" ],"edition" : "Developer","description" : "test","country" : "TR","adminEmail" : "ferhat@copa.do"}';
        sod.Developer_Hub_Org__c = org1.Id;
        insert sod;

        Scratch_Org_Project_Template__c sopt = new Scratch_Org_Project_Template__c();
        sopt.Name = 'Test';
        sopt.Developer_Hub_Org__c = org1.Id;
        sopt.Source_Org_Credential__c = org.Id;
        sopt.Project_JSON__c = '{"sourceApiVersion" : "41.0","sfdcLoginUrl" : "https://login.salesforce.com","selectedArtifactIDs" : [ "' + art.Id + '" ],"packageDirectories" : [ {"path" : "Artifact2","defaultArtifact" : true}, {"path" : "MyFirstArtifactJG","defaultArtifact" : false} ],"namespace" : "","metadataSourceName" : null,"metadataSource" : null}';
        insert sopt;

        List<Org__c> orgCredential2List = new List<Org__c>();
        Org__c orgActiveScratch = testMethodUtilities.create('Scratch Org 2', 'Scratch Org', 'password345', 'orgId3', 'token3', 'test3@test3.com', System.now());
        orgActiveScratch.Scratch_Org_Status__c = 'Active';
        orgActiveScratch.Developer_Hub_Org__c = org1.Id;
        orgCredential2List.add(orgActiveScratch);
        Org__c orgDeletedScratch = testMethodUtilities.create('Scratch Org 3', 'Scratch Org', 'password456', 'orgId2', 'token2', 'test2@test2.com', System.now());
        orgDeletedScratch.Scratch_Org_Status__c = 'Deleted';
        orgDeletedScratch.Developer_Hub_Org__c = org1.Id;
        orgCredential2List.add(orgDeletedScratch);
        insert orgCredential2List;

        Attachment att5 = new Attachment();
        att5.Body = Blob.valueOf('{"status":0,"result":{"username":"dev4@copa.do","id":"00D58000000pQecEAE","connectedStatus":"Connected","accessToken":"00D58000000pQec!AQgAQC4A2E0Cklo.S_h8e.egeG1sPXNc0h_2rzJ3QEXGtbYHoSfUdWb4tk0yu6T75ltyEsdYKa6HJiQNcCkkykv5Vu.KxOGx","instanceUrl":"https://eu6.salesforce.com","clientId":"SalesforceDevelopmentExperience"}}');
        att5.Name = 'ScratchOrgDisplay.json';
        att5.ParentId = orgActiveScratch.Id;
        insert att5;

        List<Deployment_Flow__c> dfList = new List<Deployment_Flow__c>();
        Deployment_Flow__c df = new Deployment_Flow__c();
        df.Name = 'Deployment Flow';
        df.Active__c = true;
        df.Git_Repository__c = gitRepo.Id;
        df.Main_Branch__c = 'master';
        df.Enable_Copado_DX__c = true;
        df.Copado_DX_Mode__c = 'Git Artifacts';
        dfList.add(df);

        Deployment_Flow__c df1 = new Deployment_Flow__c();
        df1.Name = 'Deployment Flow 1';
        df1.Active__c = true;
        df1.Git_Repository__c = gitRepo.Id;
        df1.Main_Branch__c = 'master';
        df1.Enable_Copado_DX__c = true;
        df1.Copado_DX_Mode__c = 'Git Artifacts';
        dfList.add(df1);
        insert dfList;

        List<Deployment_Flow_Step__c> dfsList = new List<Deployment_Flow_Step__c>();
        Deployment_Flow_Step__c dfs = new Deployment_Flow_Step__c();
        dfs.Deployment_Flow__c = df.Id;
        dfs.Destination_Environment__c = env2.Id;
        dfs.Source_Environment__c = env1.Id;
        dfs.Branch__c = 'Project';
        dfsList.add(dfs);

        Deployment_Flow_Step__c dfs1 = new Deployment_Flow_Step__c();
        dfs1.Deployment_Flow__c = df1.Id;
        dfs1.Destination_Environment__c = env2.Id;
        dfs1.Source_Environment__c = env1.Id;
        dfs1.Branch__c = 'Project';
        dfs1.Enable_as_Scratch_Org_Destination__c = 'Default DX Target';
        dfsList.add(dfs1);

        Deployment_Flow_Step__c dfs2 = new Deployment_Flow_Step__c();
        dfs2.Deployment_Flow__c = df1.Id;
        dfs2.Destination_Environment__c = env2.Id;
        dfs2.Source_Environment__c = env3.Id;
        dfs2.Branch__c = 'Project 1';
        dfs2.Enable_as_Scratch_Org_Destination__c = 'DX Target';
        dfsList.add(dfs2);
        insert dfsList;

        List<Project__c> prList = new List<Project__c>();
        Project__c project = new Project__c();
        project.Name = 'Test Project';
        project.Deployment_Flow__c = df.Id;
        prList.add(project);

        Project__c project1 = new Project__c();
        project1.Name = 'Test Project 1';
        project1.Deployment_Flow__c = df1.Id;
        prList.add(project1);
        insert prList;

        List<User_Story__c> usList = new List<User_Story__c>();
        User_Story__c us = new User_Story__c();
        us.User_Story_Title__c = 'Error on dx operation';
        usList.add(us);

        User_Story__c us1 = new User_Story__c();
        us1.User_Story_Title__c = 'Error on dx operation 1';
        us1.Project__c = project.Id;
        usList.add(us1);

        User_Story__c us2 = new User_Story__c();
        us2.User_Story_Title__c = 'Error on dx operation 2';
        us2.Project__c = project1.Id;
        us2.Org_Credential__c = orgBranch.Id;
        usList.add(us2);

        User_Story__c us3 = new User_Story__c();
        us3.User_Story_Title__c = 'Error on dx operation 3';
        us3.Project__c = project1.Id;
        us3.Org_Credential__c = orgBranch1.Id;
        usList.add(us3);
        insert usList;

        Deployment__c deployment = testMethodUtilities.create('Deployment', System.now(), System.now(), s1Org.Id, '', 'Draft');
        insert deployment;

        Step__c step = testMethodUtilities.create('Test step', '', '', deployment.Id, 0, 'Draft', 'ApexClass');
        insert step;

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Draft', org.Id);
        insert destinationOrg;

        List<Release__c> releaseList = new List<Release__c>();
        Release__c release = new Release__c();
        release.Name = 'Release 1';
        releaseList.add(release);
        Release__c release1 = new Release__c();
        release1.Name = 'Release 2';
        release1.Project__c = project.Id;
        releaseList.add(release1);
        insert releaseList;
    }
}