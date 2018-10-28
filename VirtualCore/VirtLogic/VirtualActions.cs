using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.Entity;
using System.Data.Entity.Infrastructure;
using VirtData.models;
using System.Transactions;
using VirtData;

namespace VirtualCore.VirtLogic
{
    public class VirtualActions
    {
        private Entities _dbContext = null;
        public VirtualActions(Entities _context)
        {
            _dbContext = _context;
        }
        public VirtualActions()
        {

        }
        public void SetEntites(Entities _context)
        {
            _dbContext = _context;
        }
        public bool AddMiner(minUserModel userinfo, ref string Msg, out richUserModel user)
        {
            user = null;
            if (_dbContext.AspNetUsers.Any(a => a.Email.Equals(userinfo.Email, StringComparison.InvariantCultureIgnoreCase)))
            {
                Msg = "邮箱有重复";
            }
            if (_dbContext.AspNetUsers.Any(a => a.UserName.Equals(userinfo.userName)))
            {
                Msg = string.Concat(Msg, "用户名有重复");
            }
            if (Msg.Length > 1)
            {
                return false;
            }
            using (var scope = _dbContext.Database.BeginTransaction())
            {

                AspNetUsers anUser = new AspNetUsers();
                anUser.Email = userinfo.Email;
                anUser.EmailConfirmed = false;
                anUser.Hometown = "";
                anUser.LockoutEnabled = true;
                anUser.PhoneNumber = userinfo.phoneNumber;
                anUser.PhoneNumberConfirmed = false;
                anUser.SecurityStamp = "";
                anUser.TwoFactorEnabled = false;
                anUser.UserName = userinfo.userName;
                anUser.Id = Guid.NewGuid().ToString();
                _dbContext.AspNetUsers.Add(anUser);

                tb_UserAccount userAcc = new tb_UserAccount();
                userAcc.created = DateTime.Now;
                userAcc.endTime = DateTime.Today.AddDays(365);
                userAcc.Id = anUser.Id;
                userAcc.MinerType = userinfo.MinerType;
                userAcc.modify = DateTime.Now;
                userAcc.money = 0;
                userAcc.moneybag = "";
                userAcc.MyGrade = 1;
                userAcc.paypwd = userinfo.Safetycode;
                userAcc.RecommendA0 = 0;
                userAcc.RecommendA1 = 0;
                userAcc.RecommendA2 = 0;
                userAcc.RecommendA3 = 0;
                userAcc.RecommendB1 = 0;
                userAcc.RecommendB2 = 0;
                userAcc.RecommendB3 = 0;
                userAcc.RecommendC1 = 0;
                userAcc.RecommendC2 = 0;
                userAcc.RecommendC3 = 0;
                userAcc.RecommendS = 0;
                userAcc.Referee = userinfo.Referee;
                _dbContext.tb_UserAccount.Add(userAcc);
                decimal Price = _dbContext.tb_MinerType.Single(m => m.id == userinfo.MinerType).price;
                //处理推荐人级别
                tb_UserAccount refPerson = _dbContext.tb_UserAccount.Include("tb_grade").Single(r => r.Id == userinfo.Referee);
                upgradeAction(refPerson, "A0");


                //处理推荐奖励
                RecommendedAwards(refPerson, Price, null, userinfo.userName);
                _dbContext.SaveChanges();
                //提交事务
                scope.Commit();
                return true;
            }
            return false;
        }

        /// <summary>
        /// 处理推荐人级别
        /// </summary>
        /// <param name="user">推荐人</param>
        /// <param name="AddedGrade">名下加了一个什么级别</param>
        private void upgradeAction(tb_UserAccount user, string AddedGrade)
        {
            switch (AddedGrade)
            {
                case "A0"://如果是加了一个A0
                    user.RecommendA0 = user.RecommendA0 + 1;
                    switch (user.tb_grade.grade)
                    {
                        case "A0":
                            if (user.RecommendA0 == 10)
                            {
                                user.MyGrade += 1;
                                this.AddEventLog("升级为A1", "推荐了10个A0", user.Id);
                                tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                                upgradeAction(refuser, "A1");
                            }
                            break;
                        case "A1":
                            if (user.RecommendA1 > 0 && user.RecommendA0 == 10)
                            {
                                user.MyGrade += 1;
                                this.AddEventLog("升级为A2", "推荐了1个A1和10个A0", user.Id);
                                tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                                upgradeAction(refuser, "A2");
                            }
                            break;
                    }
                    break;
                case "A1":
                    user.RecommendA1 += 1;
                    switch (user.tb_grade.grade)
                    {
                        case "A1":
                            if (user.RecommendA0 >= 10)
                            {
                                user.MyGrade += 1;
                                this.AddEventLog("升级为A2", "推荐了10个A0和1个A1", user.Id);
                                tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                                upgradeAction(refuser, "A2");
                            }
                            break;
                        case "A2":
                            if (user.RecommendA0 >= 10 && user.RecommendA1 == 2)
                            {
                                user.MyGrade += 1;
                                this.AddEventLog("升级为A3", "推荐了10个以上A0和2个A1", user.Id);
                                tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                                upgradeAction(refuser, "A3");
                            }
                            break;
                        case "A3":
                            if (user.RecommendA3 > 0 && user.RecommendA1 == 2)
                            {
                                user.MyGrade += 1;
                                this.AddEventLog("升级为B1", "推荐了1个A3和2个A1", user.Id);
                                tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                                upgradeAction(refuser, "B1");
                            }
                            break;
                        case "B1":
                            if (user.RecommendA3 == 2)
                            {
                                user.MyGrade += 1;
                                this.AddEventLog("升级为B2", "推荐了2个A3和1个A1", user.Id);
                                tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                                upgradeAction(refuser, "B2");
                            }
                            break;
                    }

                    break;
                case "A3":
                    user.RecommendA3 += 1;
                    switch (user.tb_grade.grade)
                    {
                        case "A3":
                            if (user.RecommendA1 >= 2)
                            {
                                user.MyGrade += 1;
                                this.AddEventLog("升级为B1", "推荐了2个及以上A1和1个A3", user.Id);
                                tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                                upgradeAction(refuser, "B1");
                            }
                            break;
                        case "B1":
                            if (user.RecommendA3 == 2)
                            {
                                user.MyGrade += 1;
                                this.AddEventLog("升级为B2", "推荐了2个及以上A1和2个A3", user.Id);
                                tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                                upgradeAction(refuser, "B2");
                            }
                            break;
                        case "B2":
                            if (user.RecommendA3 == 3)
                            {
                                user.MyGrade += 1;
                                this.AddEventLog("升级为B3", "推荐了3个A3", user.Id);
                                tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                                upgradeAction(refuser, "B3");
                            }
                            break;
                        case "B3":
                            if (user.RecommendB3 > 0 && user.RecommendA3 == 2)
                            {
                                user.MyGrade += 1;
                                this.AddEventLog("升级为C1", "推荐了1个以上B3和2个A3", user.Id);
                                tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                                upgradeAction(refuser, "C1");
                            }
                            break;
                    }
                    break;
                case "B1":
                    user.RecommendB1 += 1;
                    break;
                case "B2":
                    user.RecommendB2 += 1;
                    break;
                case "B3":
                    user.RecommendB3 += 1;
                    if (user.RecommendA3 >= 2 && user.MyGrade < (int)UserGrade.C1)
                    {
                        user.MyGrade = (int)UserGrade.C1;
                        this.AddEventLog("升级为C1", "推荐了2个以上A3和1个B3", user.Id);
                        tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                        upgradeAction(refuser, "C1");
                    }
                    else if (user.RecommendA3 > 0 && user.RecommendB3 == 2 && user.MyGrade < (int)UserGrade.C2)
                    {
                        user.MyGrade = (int)UserGrade.C2;
                        this.AddEventLog("升级为C2", "推荐了1个以上A3和2个B3", user.Id);
                        tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                        upgradeAction(refuser, "C2");
                    }
                    else if (user.RecommendB3 == 3 && user.MyGrade < (int)UserGrade.C3)
                    {
                        user.MyGrade = (int)UserGrade.C3;
                        this.AddEventLog("升级为C3", "推荐了3个B3", user.Id);
                        tb_UserAccount refuser = _dbContext.tb_UserAccount.Include("tb_grade").SingleOrDefault(r => r.Id == user.Referee);
                        upgradeAction(refuser, "C3");
                    }
                    break;
                case "C1":
                    user.RecommendC1 += 1;
                    if (user.RecommendC2 > 0 && user.RecommendC3 > 0 && user.MyGrade < (int)UserGrade.S)
                    {
                        user.MyGrade = (int)UserGrade.S;
                        this.AddEventLog("升级为S", "推荐了1个以上C2,C3和C1", user.Id);
                    }
                    break;
                case "C2":
                    user.RecommendC2 += 1;
                    if (user.RecommendC1 > 0 && user.RecommendC3 > 0 && user.MyGrade < (int)UserGrade.S)
                    {
                        user.MyGrade = (int)UserGrade.S;
                        this.AddEventLog("升级为S", "推荐了1个以上C1,C3和C2", user.Id);
                    }
                    break;
                case "C3":
                    user.RecommendC3 += 1;
                    if (user.RecommendC1 > 0 && user.RecommendC2 > 0 && user.MyGrade < (int)UserGrade.S)
                    {
                        user.MyGrade = (int)UserGrade.S;
                        this.AddEventLog("升级为S", "推荐了1个以上C1,C2和C3", user.Id);
                    }
                    break;
            }

        }
        private decimal _Losscoefficient = 0m;
        public decimal Losscoefficient
        {
            get
            {
                if (_Losscoefficient > 0)
                {
                    return _Losscoefficient;
                }
                _Losscoefficient = (_dbContext.tb_params.Single(x => x.paramkey.Equals(ParamNames.Losscoefficient)).paramFloatValue) ?? 18.0m;
                return _Losscoefficient;
            }
        }
        //private tb_UserAccount _systemuser = null;
        public tb_UserAccount SystemUser
        {
            get
            {
                // if (_systemuser == null)
                // {
                return _dbContext.tb_UserAccount.Where(x=>_dbContext.AspNetRoles.Any(r=>r.Id==x.Id && r.Name=="system")).First();


                // }
                //   return _systemuser;
            }
        }
        /// <summary>
        /// 发放推荐奖励
        /// </summary>
        /// <param name="user">当前要奖励的推荐人</param>
        /// <param name="AllMoney">新人对应机型的总价</param>
        /// <param name="subUser">上一个奖励的人，如果没有表示当前是直推，否则是间推</param>
        /// <param name="newUserName">新加入的用户名</param>
        private void RecommendedAwards(tb_UserAccount user, decimal AllMoney, tb_UserAccount subUser, string newUserName)
        {
            if (subUser == null)//直推
            {
                //decimal AllMoney = _dbContext.tb_MinerType.Single(x => x.id == minerType).price;

                decimal rewardMoney = AllMoney * (_dbContext.tb_grade.Single(g => g.id == user.MyGrade).Rewardpercentage) / 100;
                decimal lossMoney = rewardMoney * this.Losscoefficient / 100;
                decimal resultMoney = rewardMoney - lossMoney;
                user.money += resultMoney;
                tb_UserAccount systemUser = this.SystemUser;
                systemUser.money -= resultMoney;
                string curUserName = _dbContext.AspNetUsers.Single(a => a.Id == user.Id).UserName;
                this.Virtualtransaction(user.Id, systemUser.Id, resultMoney, "直推奖励", string.Format("推荐{0}获得{1}PUC奖励，同时扣去{2}PUC区块消耗，最终获得{3}PUC收入", newUserName,
                    rewardMoney, lossMoney, resultMoney), user.money, true);
                this.Virtualtransaction(systemUser.Id, user.Id, resultMoney, "扣除直推奖励", string.Format("{0}推荐{1}获得{2}PUC奖励，同时扣去{3}PUC区块消耗，最终获得{4}PUC收入",
                   curUserName, newUserName,
                   rewardMoney, lossMoney, resultMoney), systemUser.money, false);
                if (systemUser.money < 5000)
                {
                    systemUser.money += 10000000;
                    this.Virtualtransaction(systemUser.Id, systemUser.Id, 10000000, "自动充值", "系统自动充值", systemUser.money, true);
                }
                _dbContext.SaveChanges();
                if (!string.IsNullOrEmpty(user.Referee))
                {
                    tb_UserAccount refUser = _dbContext.tb_UserAccount.Single(a => a.Id == user.Referee);
                    RecommendedAwards(refUser, AllMoney, user, newUserName);
                }
            }
            else if (user.MyGrade > subUser.MyGrade)
            {
                decimal myRewardpercentage = _dbContext.tb_grade.Single(g => g.id == user.MyGrade).Rewardpercentage;
                decimal preRewardpercentage = _dbContext.tb_grade.Single(g => g.id == subUser.MyGrade).Rewardpercentage;
                decimal rewardMoney = AllMoney * (myRewardpercentage - preRewardpercentage) / 100;
                decimal lossMoney = rewardMoney * this.Losscoefficient / 100;
                decimal resultMoney = rewardMoney - lossMoney;
                tb_UserAccount systemUser = this.SystemUser;
                systemUser.money -= resultMoney;
                string curUserName = _dbContext.AspNetUsers.Single(a => a.Id == user.Id).UserName;
                this.Virtualtransaction(user.Id, systemUser.Id, resultMoney, "间推奖励", string.Format("间接推荐{0}获得{1}PUC奖励，同时扣去{2}PUC区块消耗，最终获得{3}PUC收入", newUserName,
                    rewardMoney, lossMoney, resultMoney), user.money, true);
                this.Virtualtransaction(systemUser.Id, user.Id, resultMoney, "扣除间推奖励", string.Format("{0}间接推荐{1}获得{2}PUC奖励，同时扣去{3}PUC区块消耗，最终获得{4}PUC收入",
                   curUserName, newUserName,
                   rewardMoney, lossMoney, resultMoney), systemUser.money, false);
                if (systemUser.money < 5000)
                {
                    systemUser.money += 10000000;
                    this.Virtualtransaction(systemUser.Id, systemUser.Id, 10000000, "自动充值", "系统自动充值", systemUser.money, true);
                }
                _dbContext.SaveChanges();
                if (!string.IsNullOrEmpty(user.Referee))
                {
                    tb_UserAccount refUser = _dbContext.tb_UserAccount.Single(a => a.Id == user.Referee);
                    RecommendedAwards(refUser, AllMoney, user, newUserName);
                }
            }
        }
        /// <summary>
        /// 生成交易记录
        /// </summary>
        /// <param name="fromUserId">针对他的流水</param>
        /// <param name="ToUserId">交易另一方</param>
        /// <param name="Money">交易金额</param>
        /// <param name="flowType">交易类型</param>
        /// <param name="desc">描述</param>
        /// <param name="curMoney">账户剩余金额</param>
        /// <param name="isIncome">fromUser是收到钱吗</param>
        private void Virtualtransaction(string fromUserId, string ToUserId, decimal Money, string flowType, string desc, decimal curMoney, bool isIncome)
        {
            tb_Capitalflow cf = new tb_Capitalflow();
            cf.userid = fromUserId;
            cf.flowType = flowType;
            cf.money = Money;
            cf.otherUser = ToUserId;
            cf.describe = desc;
            cf.curMoney = curMoney;
            cf.created = DateTime.Now;
            _dbContext.tb_Capitalflow.Add(cf);
        }

        private bool DoTransferAccount(string fromuserId, string touserId, decimal money, ref string errmsg)
        {
            using (var scope = _dbContext.Database.BeginTransaction())
            {
                tb_UserAccount fromUser = _dbContext.tb_UserAccount.Include("AspNetUsers").Single(x => x.Id == fromuserId);
                if (fromUser.money < money)
                {
                    errmsg = "账户余额不足";
                    return false;
                }
                tb_UserAccount toUser = _dbContext.tb_UserAccount.Include("AspNetUsers").Single(x => x.Id == touserId);

                tb_params transcondition = _dbContext.tb_params.FirstOrDefault(x => x.paramkey.Equals(ParamNames.Allowanytransfer));
                if(transcondition!=null && transcondition.paramIntValue != 1)
                {
                    if (!IsTreeTransferAccount(fromUser, toUser, fromUser.created < toUser.created))
                    {
                        errmsg = "转账人之间不存在直接或间接推荐关系，不允许转账";
                        return false;
                    }
                }

                tb_params tcf = _dbContext.tb_params.FirstOrDefault(a => a.paramkey == ParamNames.Transfercoefficient);
               
                fromUser.money -= money;
                decimal recMoney = money - (tcf == null ? 0m : tcf.paramFloatValue.HasValue ? money * tcf.paramFloatValue.Value / 100 : 0m);
                toUser.money += recMoney;
                decimal profit = money - recMoney;
                this.Virtualtransaction(fromuserId, touserId, money, "转账支出", string.Format("转账给{0},到账金额{1}PUC", toUser.AspNetUsers.UserName, recMoney), fromUser.money, false);
                this.Virtualtransaction(touserId, fromuserId, recMoney, "转账收入", string.Concat(string.Format("获得{0}的转账{1}PUC", fromUser.AspNetUsers.UserName, money),
                    recMoney < money ? string.Format(",扣除转账手续费：{0}PUC，实际到账{1}PUC", money - recMoney, recMoney) : ""), toUser.money, true);
                if (profit > 0)
                {
                    tb_UserAccount systemuser = this.SystemUser;
                    systemuser.money += profit;
                    this.Virtualtransaction(SystemUser.Id, fromuserId, profit, "获得转账手续费", string.Format("获得{0}转账给{1}的转账手续费", fromUser.AspNetUsers.UserName, toUser.AspNetUsers.UserName),
                        systemuser.money, true);
                }
                _dbContext.SaveChanges();
                scope.Commit();
                return true;
            }
        }
        /// <summary>
        /// 是否是树型转账
        /// </summary>
        /// <param name="fromuser"></param>
        /// <param name="toUser"></param>
        /// <param name="isOldFirst">是否是先注册的在前面</param>
        /// <returns></returns>
        private bool IsTreeTransferAccount(tb_UserAccount fromuser,tb_UserAccount toUser,bool isOldFirst)
        {
            if (isOldFirst)
            {
                if (fromuser.created < toUser.created)
                {
                    if (toUser.Referee == fromuser.Id)
                    {
                        return true;
                    }
                    toUser = _dbContext.tb_UserAccount.SingleOrDefault(x => x.Id == toUser.Referee);
                    return IsTreeTransferAccount(fromuser, toUser, isOldFirst);
                }
            }
            else
            {
                if (fromuser.created > toUser.created)
                {
                    if (fromuser.Referee == toUser.Id)
                    {
                        return true;
                    }
                    fromuser = _dbContext.tb_UserAccount.SingleOrDefault(x => x.Id == fromuser.Referee);
                    return IsTreeTransferAccount(fromuser, toUser, isOldFirst);
                }
            }
            return false;
        }

        private void AddEventLog(string enentType,string enentDesc,string userid)
        {
            tb_eventlog evl = new tb_eventlog();
            evl.enventtype = enentType;
            evl.eventdesc = enentDesc;
            evl.userid = userid;
            evl.created = DateTime.Now;
            _dbContext.tb_eventlog.Add(evl);
        }
    }
}