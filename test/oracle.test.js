const { expectRevert, expectEvent, time, ether } = require('@openzeppelin/test-helpers');
const assert = require('assert');

const Oracle = artifacts.require("Oracle");
const Consumer = artifacts.require("Consumer");

contract("Oracle", (accounts) => {
    let oracle;
    let consumer;
    const [admin, reporter1, consumer1] = accounts;
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

    beforeEach(async () => {
        // Contract instances
        oracle = await Oracle.new(admin, { from: admin });
        consumer = await Consumer.new(oracle.address, { from: admin });
    });

    /* ********************************************************************** 
     *                         ORACLE contract 
     * **********************************************************************/

    it("updateReporter(): should not update reporter - only admin", async () => {
        await expectRevert(
            oracle.updateReporter(reporter1, true, { from: reporter1 }),
            'only admin'
        );
    });

    it("updateReporter(): should update reporter", async () => {
        await oracle.updateReporter(reporter1, true, { from: admin });

        assert(await oracle.reporters.call(reporter1) === true, 'reporter should be valid');
    });


    it("updateData(): should not update data - only reporter", async () => {
        await expectRevert(
            oracle.updateData(1, 'prova', { from: admin }),
            'only valid reporter'
        );
    });

    it("updateData(): should update data", async () => {
        await oracle.updateReporter(reporter1, true, { from: admin });
        await oracle.updateData(1, 'test_data', { from: reporter1 });

        const { _, value } = await oracle.data.call(1);
        assert(value.toString() === 'test_data')
    });

    it("getData(): should not get data - no data available", async () => {
        await oracle.updateReporter(reporter1, true, { from: admin });
        await oracle.updateData(1, 'test_data', { from: reporter1 });

        const { isValid, date, value } = await oracle.getData(4);
        assert(isValid === false, 'should not be valid data');
        assert(date.toString() === '0', 'data should be 0');
        assert(value === '', 'value should be empty');

    });

    it("getData(): should get data", async () => {
        await oracle.updateReporter(reporter1, true, { from: admin });
        await oracle.updateData(1, 'test_data', { from: reporter1 });

        const { isValid, date, value } = await oracle.getData(1);
        assert(isValid === true, 'should be valid data');
        assert(date.toString() !== '0', 'data should not be 0');
        assert(value === 'test_data', 'value should be <test_data>');
    });

    /* ********************************************************************** 
     *                         CONSUMER contract 
     * **********************************************************************/

    it("foo(): should not foo - data not valid", async () => {
        await expectRevert(
            consumer.foo(1, { from: consumer1 }),
            'data not valid'
        );
    });

    it("foo(): should not foo - data too old", async () => {
        await oracle.updateReporter(reporter1, true, { from: admin });
        await oracle.updateData(1, 'test_data', { from: reporter1 });
        await time.increase(time.duration.hours(4));
        await expectRevert(
            consumer.foo(1, { from: consumer1 }),
            'data too old'
        );
    });

    it("foo(): should foo", async () => {
        await oracle.updateReporter(reporter1, true, { from: admin });
        await oracle.updateData(1, 'test_data', { from: reporter1 });
        await consumer.foo(1, { from: consumer1 });
        //do stuff should be checked here
    });

});