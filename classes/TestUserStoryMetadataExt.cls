@isTest
private class TestUserStoryMetadataExt {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void test(){
    	Project__c testProject = CMTestMethodUtilities.createProject('my project');
        testProject.Index_Metadata__c = true;
        insert testProject;


        List<User_Story__c> uList = new List<User_Story__c>();
        User_Story__c testUserStory1 = CMTestMethodUtilities.createUserStory('test');
        testUserStory1.Project__c = testProject.Id;
        uList.add(testUserStory1);
        User_Story__c testUserStory2 = CMTestMethodUtilities.createUserStory('test2');
        testUserStory2.Project__c = testProject.Id;
        uList.add(testUserStory2);
        User_Story__c testUserStory3 = CMTestMethodUtilities.createUserStory('test3');
        testUserStory2.Project__c = testProject.Id;
        uList.add(testUserStory3);
        insert uList;


        List<User_Story_Metadata__c> uMList = new List<User_Story_Metadata__c>();
        User_Story_Metadata__c usm1 = new User_Story_Metadata__c(Name='US-0006186 CustomObject.Account',Metadata_API_Name__c='CustomObject.Account',User_Story__c=testUserStory1.Id,Status__c='Potential Conflict');
        uMList.add(usm1);
        User_Story_Metadata__c usm2 = new User_Story_Metadata__c(Name='US-0000777 CustomObject.Account',Metadata_API_Name__c='CustomObject.Account',User_Story__c=testUserStory2.Id,Status__c='Potential Conflict');
        uMList.add(usm2);
        User_Story_Metadata__c usm3 = new User_Story_Metadata__c(Name='US-0000567 CustomObject.Account',Metadata_API_Name__c='CustomObject.Account',User_Story__c=testUserStory3.Id,Status__c='Potential Conflict');
        uMList.add(usm3);
        User_Story_Metadata__c usm4 = new User_Story_Metadata__c(Name='US-0006186 CustomLabel.VALIDATE',Metadata_API_Name__c='CustomLabel.VALIDATE',User_Story__c=testUserStory1.Id,Status__c='On Hold');
        uMList.add(usm4);
        User_Story_Metadata__c usm5 = new User_Story_Metadata__c(Name='US-0000777 ApexClass.Helper',Metadata_API_Name__c='ApexClass.Helper',User_Story__c=testUserStory2.Id,Status__c='In Review');
        uMList.add(usm5);
        User_Story_Metadata__c usm6 = new User_Story_Metadata__c(Name='US-0000567 CustomField.Account.XYZ__c',Metadata_API_Name__c='CustomField.Account.XYZ__c',User_Story__c=testUserStory3.Id,Status__c='');
        uMList.add(usm6);
        insert uMList;

        System.assertEquals(6, [select count() from User_Story_Metadata__c]);
        System.assertEquals(3, [select count() from User_Story_Metadata__c where Status__c='Potential Conflict']);
        System.assertEquals(3, [select count() from User_Story_Metadata__c where Status__c='Potential Conflict' and Metadata_API_Name__c='CustomObject.Account']);     

        Test.startTest(); 

        ApexPages.currentPage().getParameters().put('Status','Conflict Resolved');
        ApexPages.currentPage().getParameters().put('metadataId',usm3.Id);

        UserStoryMetadataExt ext = new UserStoryMetadataExt(new ApexPages.StandardController(usm3));
        system.debug('#### UserStoryMetadata:"'+ext.usMetadata);
        system.assertEquals('Potential Conflict', ext.usMetadata.Status__c);
        system.assertEquals(2, ext.usMetadatas.size());
        system.assertEquals(5, ext.getStatuses().size());//JG: now we "Back Promoted"

        ext.updateStatus();
        system.assertEquals('Conflict Resolved', ext.usMetadata.Status__c);

        ext.metadataId = '';
		ext.updateStatuses();

        Test.stopTest();

        System.assertEquals(0, [select count() from User_Story_Metadata__c where Status__c='Potential Conflict']);
        System.assertEquals(3, [select count() from User_Story_Metadata__c where Status__c='Conflict Resolved' AND Metadata_API_Name__c='CustomObject.Account']);
        ext.deleteJob();
    }
}