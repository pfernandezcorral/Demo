@isTest
public class TestUserStoryImportSetController {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    public class testData {
        public List<User_Story__c> userStories = new List<User_Story__c>();
        public User_Story__c usResult = new User_Story__c();
        public List<User_Story_Commit__c> usCommits = new List<User_Story_Commit__c>();
        public List<Git_Org_Commit__c> commits = new List<Git_Org_Commit__c>();
        public List<Attachment> commitAttachments = new List<Attachment>();
        User_Story__c usWithoutcommits;
    }
    
    static testData generateData() {
        testData D = new testData();
        Org__c o = new Org__c(name = 'test');
        insert o;
        
        Git_Repository__c r = new Git_Repository__c(name='test');
        insert r;
        
        Git_Backup__c bk = new Git_Backup__c(Git_Repository__c = r.id, Org__c = o.id);
        insert bk;
        
        Git_Org_Commit__c c1 = new Git_Org_Commit__c(Git_Backup__c = bk.id, Org__c = o.id, Commit_Id__c='b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c=Date.today(),Commit_Message__c='test', Status__c ='Complete');
        insert c1;

        Git_Org_Commit__c c2 = new Git_Org_Commit__c(Git_Backup__c = bk.id, Org__c = o.id, Commit_Id__c='b7adccf3937495e8928d1023c5a5c644198b8975', Commit_Date__c=Date.today(),Commit_Message__c='test 2', Status__c ='Complete');
        insert c2;

        // Metadata selections via the grid
        Attachment att1 = new Attachment(ParentId=c1.Id, Name='Metadata', Body=Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true,"r":true}, {"t":"EmailTemplate","n":"Template2","s":false}]'));
        insert att1;
        // insert separately, so it is the latest attachment
        Attachment att2 = new Attachment(ParentId=c2.Id, Name='Metadata', Body=Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true,"r":false}, {"t":"EmailTemplate","n":"a_Template","s":true}]'));
        insert att2;
        D.commitAttachments.add(att1);
        D.commitAttachments.add(att2);
        
	    User_Story__c us = new User_Story__c();
        insert us;
	    User_Story__c us2 = new User_Story__c();
        insert us2;
        D.userStories.add(us);
        D.userStories.add(us2);

	    D.usWithoutcommits = new User_Story__c();
        insert D.uswithoutcommits;
        
        // user story that will hold the results
        insert D.usResult;
        
        String usName = [select Name from User_Story__c where id=:us.Id].Name;
        User_Story_Commit__c uc1 = new User_Story_Commit__c(User_Story__c = us.id, Snapshot_Commit__c = c1.id);
        insert uc1;
        D.usCommits.add(uc1);
        User_Story_Commit__c uc2 = new User_Story_Commit__c(User_Story__c = us2.id, Snapshot_Commit__c = c2.id);
        insert uc2;
        D.usCommits.add(uc2);
        return D;
	}
    
    static testMethod void test_empty(){
        testData D = generateData();
        
        // now "select" a few US in "userStories", and test the controller
        PageReference pageRef = Page.UserStoryAssignment;
        Test.setCurrentPage(pageRef);
        
        List<User_Story__c> empties = new List<User_Story__c>();
        empties.add(D.usWithoutcommits);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(empties);
        UserStoryImportSetController ext = new UserStoryImportSetController(con);
        ext.records = empties;
        ext.initPage();
        
        Test.startTest();
        ext.dummy.User_Story__c = D.usResult.Id;
        PageReference result = ext.assign();
        system.assertEquals( null, result, 'User stories without metadata should show an error message');
        Test.stopTest();
    }
    
    static testMethod void test_with_commits(){
        testData D = generateData();
        
        // now "select" a few US in "userStories", and test the controller
        PageReference pageRef = Page.UserStoryAssignment;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(D.userStories);
        UserStoryImportSetController ext = new UserStoryImportSetController(con);
        ext.records = D.userStories;
        ext.initPage();
        System.assertEquals(2, D.userStories.size());
        System.assertEquals(2, ext.records.size());
        
        Test.startTest();
        ext.dummy.User_Story__c = D.usResult.Id;
        PageReference result = ext.assign();

        PageReference pref = Page.UserStoryCommitIntermediary;
        String expected = pref.getUrl();

        system.assertNotEquals( null, result, 'User stories with metadata should be able to advance, but it threw an error');
        system.assert( result.getUrl().startsWith(expected), 'got: '+result.getUrl()+' expected: '+expected+';' );
        system.assertEquals( result.getParameters().get('id'), D.usResult.Id );
        system.assertNotEquals( result.getParameters().get('MetadataPreselectionId'), '' );
        
        String aid = result.getParameters().get('MetadataPreselectionId');
        Attachment a = [SELECT Id, Body FROM Attachment WHERE id = :aid];
        System.debug('Body='+a.Body.toString());
        List<UserStoryImportSetController.MetaDataItem> metadata = (List<UserStoryImportSetController.MetaDataItem>)JSON.deserialize(a.Body.toString(), List<UserStoryImportSetController.MetaDataItem>.class);
        integer timesFound = 0;
        for(UserStoryImportSetController.MetaDataItem mi : metadata) {
            System.debug('-rs: '+mi.s+' '+mi.r+' '+mi.n+' '+mi+' ; '+mi.t.equals('EmailTemplate') +','+ mi.n.equals('Template1'));
            if(mi.t.equals('EmailTemplate') && mi.n.equals('Template1') ) {
		        system.assertNotEquals( true, mi.r );
                timesFound++;
            }
        }
        system.assertEquals( 1, timesFound );
        Test.stopTest();        
    }
}