from brownie import network, accounts, exceptions
from scripts.ezscripts import LOCAL_BLOCKCHAINS, get_account
from scripts.deploy import deploy_fund_me
import pytest


## This makes our test work independent from the network it is on
def test_can_fund_and_withdraw():
    account = get_account()
    fund_me = deploy_fund_me()
    enterance_fee = fund_me.getEntranceFee()
    txn = fund_me.fund({"from": account, "value": enterance_fee})
    txn.wait(1)
    assert fund_me.addressToAmountFunded(account.address) == enterance_fee
    txn2 = fund_me.withdraw({"from": account})
    txn2.wait(1)
    assert fund_me.addressToAmountFunded(account.address) == 0


def test_only_owner_can_withdraw():
    if network.show_active() not in LOCAL_BLOCKCHAINS:
        pytest.skip("Only for local testing")
    # account = get_account()
    fund_me = deploy_fund_me()
    bad_actor = accounts.add()
    with pytest.raises(exceptions.VirtualMachineError):
        fund_me.withdraw({"from": bad_actor})
        # We are telling the test here that yo we want this to fail. So pass this test if it fails
