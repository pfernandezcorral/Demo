<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>snoopy1</fullName>
        <field>AccountNumber</field>
        <name>snoopy1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>LP_ACCCreateMyGoAccountTask</fullName>
        <actions>
            <name>LP_ACCCreateMyGoAccountTask</name>
            <type>FlowAction</type>
        </actions>
        <active>true</active>
        <description>ACC.LP Create a task on Account when MyGo Account record is created.</description>
        <formula>AND(  $Setup.LP_ProfileExtension__c.LP_EnableWFsTaskAutomation__c = 1,  $User.LP_MyGoAccountFollowUpTask__c = TRUE,  LP_CreatedByExternalSystem__c = TRUE, NOT(ISBLANK (TEXT(LP_Segment__c ) )),  (CONTAINS( $User.LP_SMESegment__c , TEXT(LP_Segment__c )))    )</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>This is a test WF</fullName>
        <actions>
            <name>This_is_a_test_WF_action</name>
            <type>FlowAction</type>
        </actions>
        <actions>
            <name>This_is_a_test_WF_action2</name>
            <type>FlowAction</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Account.LP_Active__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>snoopy</fullName>
        <actions>
            <name>snoopy1</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Name</field>
            <operation>equals</operation>
            <value>test</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
