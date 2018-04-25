@isTest
public class TestGitCommitLookupController{

    static testMethod void runTest(){
        
        GitCommitLookupController con = new GitCommitLookupController();
        con.selectedRepository = 'test';
        String s = con.getFormTag();
        String s2 = con.getTextBox();
        system.assert(con.selectedRepository != null);
    }
}