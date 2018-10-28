using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VirtData.models
{
   public class webapiresult
    {
        public int code { get; set; }
        public string msg { get; set; }
        public object param { get; set; }
    }
    public enum UserGrade
    {
        A0=0,
        A1=1,
        A2=2,
        A3=3,
        B1=4,
        B2=5,
        B3=6,
        C1=7,
        C2=8,
        C3=9,
        S=10
    }
    public class ParamNames
    {
        /// <summary>
        /// 区块消耗参数名
        /// </summary>
        public static string Losscoefficient = "Losscoefficient";
        /// <summary>
        /// 转账扣除比率参数名
        /// </summary>
        public static string Transfercoefficient = "Transfercoefficient";
        /// <summary>
        /// 是否运行任意转账
        /// </summary>
        public static string Allowanytransfer = "Allowanytransfer";

    }
}
