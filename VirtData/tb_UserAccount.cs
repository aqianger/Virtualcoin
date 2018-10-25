namespace VirtData
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    public partial class tb_UserAccount
    {
        public string Id { get; set; }

        [Column(TypeName = "numeric")]
        public decimal money { get; set; }

        public DateTime created { get; set; }

        public DateTime modify { get; set; }

        public virtual AspNetUsers AspNetUsers { get; set; }
    }
}
