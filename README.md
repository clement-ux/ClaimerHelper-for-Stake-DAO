# ClaimerHelper-for-Stake-DAO
Claimer contract for claiming ALL rewards from stake dao and do extra action on top of it.

User will be able to do in a single transactions the following actions : 
- claim rewards obtained with multiple bribes 
- claim rewards obtained with veSDT and choose between following actions
    - obtain sdFrax3CRV (original reward)
    - swap sdFrax3CRV into FRAX 
    - swap sdFrax3CRV into SDT (can be locked into veSDT after)
- claim rewards obtained from lockers and strategies choose between following actions for TKN (CRV, FXS, ANGLE)
    - swap for sdTKN (help to have a better peg) and deposit into gauge (Lucas idea 🙏)
    - mint sdTKN using depositor and stake sdTKN or not
    - obtain TKN 
- relock all SDT obtained from bribes, veSDT, lockers and strategies rewards.  

This new claimer don't need to "enable gauge" anymore like the previous one, because the contract directly check on the gauge controler if the gauge is registred on it or not. And there is the possibility to blacklist a gauge, in order to don't loose security compared to previous contract. 