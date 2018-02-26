<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <flowActions>
        <fullName>Test_WF_action</fullName>
        <flow>LP_TaskAutomationFlow</flow>
        <flowInputs>
            <name>LP_CountryCode</name>
            <value>{!LP_CountryCode__c}</value>
        </flowInputs>
        <flowInputs>
            <name>LP_ParentRecordOwner</name>
            <value>{!OwnerId}</value>
        </flowInputs>
        <flowInputs>
            <name>LP_ParentWhoId</name>
            <value>{!Id}</value>
        </flowInputs>
        <flowInputs>
            <name>LP_TaskAutomationName</name>
            <value>Create SME Manual Lead Follow-up Task</value>
        </flowInputs>
        <label>Test WF action</label>
        <language>en_US</language>
        <protected>false</protected>
    </flowActions>
    <rules>
        <fullName>This is a test WF</fullName>
        <actions>
            <name>Test_WF_action</name>
            <type>FlowAction</type>
        </actions>
        <active>false</active>
        <description>Please ignore this WF. Copado Testing</description>
        <formula>AND( $Setup.LP_ProfileExtension__c.LP_EnableWFsTaskAutomation__c = 1, NOT($Profile.Id =&apos;00eW0000000QNTA&apos;), /*LP Pardot Connector*/ NOT($Profile.Id =&apos;00e37000000pBr8&apos;), /* LP SME ESB User*/ NOT($Profile.Id =&apos;00e20000001A135&apos;), /* LP ESB User*/ NOT($Profile.Id =&apos;00e20000001FwsL&apos;), /* Sys Admin User*/ $User.LP_LeadSMENewManualLeadFollowupTask__c, RecordType.DeveloperName =&apos;LP_SMELead&apos;, OR(ISBLANK($User.LP_SME_WFExcludedSegments__c), NOT(CONTAINS($User.LP_SME_WFExcludedSegments__c,TEXT( LP_Segment__c))) ) )</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
