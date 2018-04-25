@isTest
private class TestIndexMetadataJob {
    @testSetup static void setupData() {
        insert TestUtilities.getTestSettings();
    }
    static testMethod void test(){
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        testProject.Index_Metadata__c = true;
        insert testProject;
                
        User_Story__c testUserStory1 = CMTestMethodUtilities.createUserStory('test');
        testUserStory1.Project__c = testProject.Id;
        insert testUserStory1;
        Attachment at1 = new Attachment();
        at1.Name = 'MetaData';
        at1.ParentId = testUserStory1.Id;
        at1.Body = Blob.valueOf('[{"t":"CustomObject","n":"Account"},{"t":"CustomObject","n":"Contact"},{"t":"CustomField","n":"Account.Number__c"}]');
        insert at1;
        
        User_Story__c testUserStory2 = CMTestMethodUtilities.createUserStory('test');
        testUserStory2.Project__c = testProject.Id;
        insert testUserStory2;
        Attachment at2 = new Attachment();
        at2.Name = 'Git MetaData';
        at2.ParentId = testUserStory2.Id;
        //dupes are: CustomObject.Account for US1 and US2
        at2.Body = Blob.valueOf('[{"t":"CustomObject","n":"Account"},{"t":"CustomObject","n":"Opportunity"},{"t":"CustomField","n":"Account.XYZ__c"}]');
        insert at2;
        
        Attachment at3 = new Attachment();
        at3.Name = 'Delete MetaData';
        at3.ParentId = testUserStory2.Id;
        //dupes are: CustomObject.Account for US1,US2 and US3 - CustomField.Account.XYZ__c for US1 and US3
        at3.Body = Blob.valueOf('[{"t":"CustomObject","n":"Account"},{"t":"CustomObject","n":"OpportunityLineItem"},{"t":"CustomField","n":"Account.XYZ__c"}]');
        insert at3;
        
        Test.startTest();
        Database.executeBatch(new IndexMetadataJob(), 50);
        Test.stopTest();
        for (User_Story_Metadata__c md:[select Status__c, Metadata_API_Name__c from User_Story_Metadata__c])System.debug('**** ' + md);
        System.assertEquals(9, [select count() from User_Story_Metadata__c]);
        System.assertEquals(5, [select count() from User_Story_Metadata__c where Status__c='Potential Conflict']);
        System.assertEquals(3, [select count() from User_Story_Metadata__c where Status__c='Potential Conflict' and Metadata_API_Name__c='CustomObject.Account']);
        System.assertEquals(2, [select count() from User_Story_Metadata__c where Status__c='Potential Conflict' and Metadata_API_Name__c='CustomField.Account.XYZ__c']);
    }
    static testMethod void testWithUserStory() {
        Project__c testProject = CMTestMethodUtilities.createProject('my project');
        testProject.Index_Metadata__c = true;
        insert testProject;
                
        User_Story__c testUserStory1 = CMTestMethodUtilities.createUserStory('test');
        testUserStory1.Project__c = testProject.Id;
        insert testUserStory1;
        User_Story__c testUserStory2 = CMTestMethodUtilities.createUserStory('test');
        testUserStory2.Project__c = testProject.Id;
        insert testUserStory2;

        Test.startTest();

        Attachment at1 = new Attachment();
        at1.Name = 'MetaData';
        at1.ParentId = testUserStory1.Id;
        at1.Body = Blob.valueOf('[{"t":"CustomObject","n":"Account"},{"t":"CustomObject","n":"Contact"},{"t":"CustomField","n":"Account.Number__c"}]');
        insert at1;
                
        Attachment at2 = new Attachment();
        at2.Name = 'Git MetaData';
        at2.ParentId = testUserStory2.Id;
        //dupes are: CustomObject.Account for US1 and US2
        at2.Body = Blob.valueOf('[{"t":"CustomObject","n":"Account"},{"t":"CustomObject","n":"Opportunity"},{"t":"CustomField","n":"Account.XYZ__c"}]');
        insert at2;
        
        Attachment at3 = new Attachment();
        at3.Name = 'Delete MetaData';
        at3.ParentId = testUserStory2.Id;
        //dupes are: CustomObject.Account for US1,US2 and US3 - CustomField.Account.XYZ__c for US1 and US3
        at3.Body = Blob.valueOf('[{"t":"CustomObject","n":"Account"},{"t":"CustomObject","n":"OpportunityLineItem"},{"t":"CustomField","n":"Account.XYZ__c"}]');
        insert at3;

        Attachment at4 = new Attachment();
        at4.Name = 'Delete MetaData';
        at4.ParentId = testUserStory1.Id;
        //dupes are: CustomObject.Account for US1,US2 and US3 - CustomField.Account.XYZ__c for US1 and US3
        at4.Body = Blob.valueOf('[{"t":"CustomField","n":"Account.Number__c"}]');
        insert at4;
        delete at4;
        
        Test.stopTest();//Comments for Git Refresh

        for (User_Story_Metadata__c md:[select Status__c, Metadata_API_Name__c from User_Story_Metadata__c])System.debug('**** ' + md);
        System.assertEquals(9, [select count() from User_Story_Metadata__c]);
        System.assertEquals(5, [select count() from User_Story_Metadata__c where Status__c='Potential Conflict']);
        System.assertEquals(3, [select count() from User_Story_Metadata__c where Status__c='Potential Conflict' and Metadata_API_Name__c='CustomObject.Account']);
        System.assertEquals(2, [select count() from User_Story_Metadata__c where Status__c='Potential Conflict' and Metadata_API_Name__c='CustomField.Account.XYZ__c']);
        System.assertEquals(0, [select count() from User_Story_Metadata__c where Status__c='Potential Conflict' and Metadata_API_Name__c='CustomField.Account.Number__c']);
    }
}