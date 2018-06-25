<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update2</fullName>
        <field>Site</field>
        <name>Update2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update6</fullName>
        <field>BillingCity</field>
        <name>Update6</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update7</fullName>
        <field>BillingCountry</field>
        <name>Update7</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update8</fullName>
        <field>BillingLatitude</field>
        <name>Update8</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update9</fullName>
        <field>ShippingCity</field>
        <name>Update9</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateTBWF</fullName>
        <field>AccountNumber</field>
        <name>UpdateTBWF</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>test2</fullName>
        <field>AccountNumber</field>
        <name>test2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>test3</fullName>
        <field>Site</field>
        <name>test3</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>test4</fullName>
        <field>BillingState</field>
        <name>test4</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>test5</fullName>
        <field>BillingState</field>
        <name>test5</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>test6</fullName>
        <field>BillingPostalCode</field>
        <name>test6</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>test7</fullName>
        <field>SLA__c</field>
        <name>test7</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>test8</fullName>
        <field>TickerSymbol</field>
        <name>test8</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>test9</fullName>
        <field>AccountSource</field>
        <name>test9</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>PreviousValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update1</fullName>
        <field>AccountNumber</field>
        <name>update1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update3</fullName>
        <field>AccountSource</field>
        <name>update3</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>PreviousValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update4</fullName>
        <field>AnnualRevenue</field>
        <name>update4</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update5</fullName>
        <field>AnnualRevenue</field>
        <name>update5</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Account test</fullName>
        <actions>
            <name>Field_update1</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>test2</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>test3</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>test4</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>test5</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>test6</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>test7</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>test8</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>test9</name>
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
    <rules>
        <fullName>Testrule</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Account.IsPartner</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>TimebasedWF</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Account.Name</field>
            <operation>equals</operation>
            <value>TestTimeBased</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.AccountNumber</field>
            <operation>equals</operation>
            <value>12345</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.OwnerId</field>
            <operation>notContain</operation>
            <value>Patricia</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>UpdateTBWF</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>30</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
