namespace VirtData
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    public partial class tb_Capitalflow
    {
        [Key]
        [Column(Order = 0)]
        public int id { get; set; }

        [Key]
        [Column(Order = 1)]
        public string userid { get; set; }

        [Key]
        [Column(Order = 2)]
        [StringLength(20)]
        public string flowType { get; set; }

        [Key]
        [Column(Order = 3, TypeName = "numeric")]
        public decimal money { get; set; }

        [Key]
        [Column(Order = 4)]
        public string otherUser { get; set; }

        [Key]
        [Column(Order = 5)]
        public DateTime created { get; set; }
    }
}
