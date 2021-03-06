USE [master]
GO
/****** Object:  Database [aspnet-virtual_Currency-20181023095441]    Script Date: 10/28/2018 2:40:23 PM ******/
CREATE DATABASE [aspnet-virtual_Currency-20181023095441]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'aspnet-virtual_Currency-20181023095441', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\aspnet-virtual_Currency-20181023095441.mdf' , SIZE = 4160KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'aspnet-virtual_Currency-20181023095441_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\aspnet-virtual_Currency-20181023095441_log.ldf' , SIZE = 1040KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [aspnet-virtual_Currency-20181023095441].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET ARITHABORT OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET  ENABLE_BROKER 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET RECOVERY FULL 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET  MULTI_USER 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET DB_CHAINING OFF 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'aspnet-virtual_Currency-20181023095441', N'ON'
GO
USE [aspnet-virtual_Currency-20181023095441]
GO
/****** Object:  StoredProcedure [dbo].[AutoAddAllInterest]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AutoAddAllInterest] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @systemId nvarchar(128)
	declare @userid nvarchar(128)
	select top 1 @systemId=A.AspNetUsers_Id from AspNetUserRoles A inner join AspNetRoles B on A.AspNetRoles_Id=B.Id where B.Name='system'
	DECLARE MyCursor CURSOR 
FOR SELECT A.Id FROM tb_UserAccount A where DATEDIFF(day,getdate(),endTime)>=0 and not exists(select 1 from tb_Capitalflow where userid=A.Id and flowType='当天产出' and Datediff(day,created,getdate())=0) order by Id
    -- Insert statements for procedure here
	open MyCursor
	fetch next from MyCursor into @userid
	WHILE @@FETCH_STATUS =0
	begin
	exec AutoAddUserInterest @userid,@systemId
	fetch next from MyCursor into @userid
	end
	close MyCursor
	Deallocate MyCursor
	declare @money decimal(18,4)
	select @money=[money] from tb_UserAccount where Id=@systemId
	if(@money<1000)
	begin
	update tb_UserAccount set [money]=[money]+10000000 where Id=@systemId
	select @money=[money] from tb_UserAccount  where Id=@systemId
	insert tb_Capitalflow (userid,flowType,[money],otherUser,created,describe,curMoney,isIncome)
			values(@systemId,'自动充值',10000000,@systemId,getdate(),'自动充值',@money,1)
	end
	insert into tb_eventlog(enventtype,eventdesc,created,userid)values('自动发息','已执行自动发息过程',getdate(),@systemId)
END

GO
/****** Object:  StoredProcedure [dbo].[AutoAddUserInterest]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AutoAddUserInterest] 
	(@userId nvarchar(128),@systemId nvarchar(128))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @curUserId nvarchar(128)
	declare @MyGrade integer
	declare @created datetime
	declare @endTime datetime
	declare @interestrate decimal(18,4)
	declare @money decimal(18,4)
	declare @addmoney decimal(18,4)
	select @curUserId=Id,
	@MyGrade=MyGrade,
	@created=created,
	@endTime=endTime,@money=[money] from tb_UserAccount  where Id=@userId
	if(@curUserId is null or @curUserId ='')
	begin
	return
	end
	if(Dateadd(day,1, @endTime)<getdate())
	begin
	insert into tb_eventlog(enventtype,eventdesc,created,userid)values('用户已到期','用户到期时间'+CONVERT(varchar(120),@endTime,120),getdate(),@userId)
	return
	end
	select top 1 @interestrate=paramFloatValue  from tb_params where paramkey like 'minerType'+cast(@MyGrade as varchar(1))+'-_' and Datediff(day,@created, getdate())<=paramIntValue
	order by paramkey
	if(@interestrate<=0)
	begin
	insert into tb_eventlog(enventtype,eventdesc,created,userid)values('没找到利率','minerType'+cast(@MyGrade as varchar(1))+'-_',getdate(),@userid)
	return
		end
	if(exists(select 1 from tb_Capitalflow where userid=@userId and flowType='当天产出' and Datediff(day,created,getdate())=0))
begin
return
end
	
	set @addmoney=@money*@interestrate/100;
	begin try  
       begin transaction 
            update tb_UserAccount set [money]=[money]+@addmoney where Id=@userid
			select @money= [money] from tb_UserAccount where Id=@userid
			insert tb_Capitalflow (userid,flowType,[money],otherUser,created,describe,curMoney,isIncome)
			values(@userId,'当天产出',@addmoney,@systemId,getdate(),'当天产出利息',@money,1)
			update tb_UserAccount set [money]=[money]-@addmoney where Id=@systemId
			select @money= [money] from tb_UserAccount where Id=@systemId
			insert tb_Capitalflow (userid,flowType,[money],otherUser,created,describe,curMoney,isIncome)
			values(@systemId,'利息支出',@addmoney,@userId,getdate(),'当天支出利息',@money,0)
       commit transaction 
end try 
begin catch 
             select ERROR_NUMBER() as errornumber 
       rollback transaction 
end catch

END
GO
/****** Object:  Table [dbo].[AspNetRoles]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetRoles](
	[Id] [nvarchar](128) NOT NULL,
	[Name] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK_AspNetRoles] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AspNetUserClaims]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetUserClaims](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](128) NOT NULL,
	[ClaimType] [nvarchar](max) NULL,
	[ClaimValue] [nvarchar](max) NULL,
 CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AspNetUserLogins]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetUserLogins](
	[LoginProvider] [nvarchar](128) NOT NULL,
	[ProviderKey] [nvarchar](128) NOT NULL,
	[UserId] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY CLUSTERED 
(
	[LoginProvider] ASC,
	[ProviderKey] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AspNetUserRoles]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetUserRoles](
	[AspNetRoles_Id] [nvarchar](128) NOT NULL,
	[AspNetUsers_Id] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY CLUSTERED 
(
	[AspNetRoles_Id] ASC,
	[AspNetUsers_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AspNetUsers]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AspNetUsers](
	[Id] [nvarchar](128) NOT NULL,
	[Hometown] [nvarchar](256) NULL,
	[Email] [nvarchar](256) NULL,
	[EmailConfirmed] [bit] NOT NULL,
	[PasswordHash] [nvarchar](256) NULL,
	[SecurityStamp] [nvarchar](256) NULL,
	[PhoneNumber] [nvarchar](15) NULL,
	[PhoneNumberConfirmed] [bit] NOT NULL,
	[TwoFactorEnabled] [bit] NOT NULL,
	[LockoutEndDateUtc] [datetime] NULL,
	[LockoutEnabled] [bit] NOT NULL,
	[AccessFailedCount] [int] NOT NULL,
	[UserName] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK_AspNetUsers] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[C__MigrationHistory]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[C__MigrationHistory](
	[MigrationId] [nvarchar](150) NOT NULL,
	[ContextKey] [nvarchar](300) NOT NULL,
	[Model] [varbinary](max) NOT NULL,
	[ProductVersion] [nvarchar](32) NOT NULL,
 CONSTRAINT [PK_C__MigrationHistory] PRIMARY KEY CLUSTERED 
(
	[MigrationId] ASC,
	[ContextKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tb_Capitalflow]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Capitalflow](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[userid] [nvarchar](128) NOT NULL,
	[flowType] [nvarchar](20) NOT NULL,
	[money] [decimal](18, 4) NOT NULL,
	[otherUser] [nvarchar](128) NOT NULL,
	[created] [datetime] NOT NULL,
	[describe] [nvarchar](200) NOT NULL,
	[curMoney] [decimal](18, 4) NOT NULL,
	[isIncome] [bit] NOT NULL,
 CONSTRAINT [PK_tb_Capitalflow] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tb_eventlog]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tb_eventlog](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[enventtype] [nvarchar](50) NOT NULL,
	[eventdesc] [nvarchar](256) NOT NULL,
	[created] [datetime] NOT NULL,
	[userid] [varchar](128) NULL,
 CONSTRAINT [PK_tb_eventlog] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tb_grade]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tb_grade](
	[id] [int] NOT NULL,
	[grade] [varchar](2) NOT NULL,
	[Rewardpercentage] [decimal](18, 2) NOT NULL,
 CONSTRAINT [PK_tb_grade] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tb_MinerType]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_MinerType](
	[id] [int] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[price] [decimal](18, 4) NOT NULL,
 CONSTRAINT [PK_tb_MinerType] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tb_Notice]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Notice](
	[nid] [int] IDENTITY(1,1) NOT NULL,
	[title] [nvarchar](250) NOT NULL,
	[content] [nvarchar](max) NOT NULL,
	[creator] [nvarchar](128) NOT NULL,
	[created] [datetime] NOT NULL,
	[isShow] [bit] NOT NULL,
 CONSTRAINT [PK_tb_Notice] PRIMARY KEY CLUSTERED 
(
	[nid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[tb_params]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tb_params](
	[id] [uniqueidentifier] NOT NULL,
	[paramkey] [varchar](50) NOT NULL,
	[paramStrValue] [nvarchar](250) NULL,
	[paramIntValue] [int] NULL,
	[paramFloatValue] [decimal](18, 4) NULL,
	[describe] [nvarchar](50) NULL,
 CONSTRAINT [PK_tb_params] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tb_UserAccount]    Script Date: 10/28/2018 2:40:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tb_UserAccount](
	[Id] [nvarchar](128) NOT NULL,
	[money] [decimal](18, 4) NOT NULL,
	[created] [datetime] NOT NULL,
	[modify] [datetime] NOT NULL,
	[paypwd] [nvarchar](256) NOT NULL,
	[moneybag] [varchar](128) NOT NULL,
	[MinerType] [int] NOT NULL,
	[endTime] [datetime] NOT NULL,
	[Referee] [nvarchar](128) NOT NULL,
	[MyGrade] [int] NOT NULL,
	[RecommendA0] [int] NOT NULL,
	[RecommendA1] [int] NOT NULL,
	[RecommendA2] [int] NOT NULL,
	[RecommendA3] [int] NOT NULL,
	[RecommendB1] [int] NOT NULL,
	[RecommendB2] [int] NOT NULL,
	[RecommendB3] [int] NOT NULL,
	[RecommendC1] [int] NOT NULL,
	[RecommendC2] [int] NOT NULL,
	[RecommendC3] [int] NOT NULL,
	[RecommendS] [int] NOT NULL,
 CONSTRAINT [PK_tb_UserAccount] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_FK_dbo_AspNetUserClaims_dbo_AspNetUsers_UserId]    Script Date: 10/28/2018 2:40:23 PM ******/
CREATE NONCLUSTERED INDEX [IX_FK_dbo_AspNetUserClaims_dbo_AspNetUsers_UserId] ON [dbo].[AspNetUserClaims]
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_FK_dbo_AspNetUserLogins_dbo_AspNetUsers_UserId]    Script Date: 10/28/2018 2:40:23 PM ******/
CREATE NONCLUSTERED INDEX [IX_FK_dbo_AspNetUserLogins_dbo_AspNetUsers_UserId] ON [dbo].[AspNetUserLogins]
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_FK_AspNetUserRoles_AspNetUsers]    Script Date: 10/28/2018 2:40:23 PM ******/
CREATE NONCLUSTERED INDEX [IX_FK_AspNetUserRoles_AspNetUsers] ON [dbo].[AspNetUserRoles]
(
	[AspNetUsers_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_FK_tb_Capitalflow_AspNetUsers]    Script Date: 10/28/2018 2:40:23 PM ******/
CREATE NONCLUSTERED INDEX [IX_FK_tb_Capitalflow_AspNetUsers] ON [dbo].[tb_Capitalflow]
(
	[userid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_FK_tb_Capitalflow_AspNetUsers1]    Script Date: 10/28/2018 2:40:23 PM ******/
CREATE NONCLUSTERED INDEX [IX_FK_tb_Capitalflow_AspNetUsers1] ON [dbo].[tb_Capitalflow]
(
	[otherUser] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_FK_tb_Notice_AspNetUsers]    Script Date: 10/28/2018 2:40:23 PM ******/
CREATE NONCLUSTERED INDEX [IX_FK_tb_Notice_AspNetUsers] ON [dbo].[tb_Notice]
(
	[creator] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_FK_tb_UserAccount_tb_grade]    Script Date: 10/28/2018 2:40:23 PM ******/
CREATE NONCLUSTERED INDEX [IX_FK_tb_UserAccount_tb_grade] ON [dbo].[tb_UserAccount]
(
	[MyGrade] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20181027-232440]    Script Date: 10/28/2018 2:40:23 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20181027-232440] ON [dbo].[tb_UserAccount]
(
	[created] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[AspNetUserClaims]  WITH CHECK ADD  CONSTRAINT [FK_dbo_AspNetUserClaims_dbo_AspNetUsers_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[AspNetUsers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AspNetUserClaims] CHECK CONSTRAINT [FK_dbo_AspNetUserClaims_dbo_AspNetUsers_UserId]
GO
ALTER TABLE [dbo].[AspNetUserLogins]  WITH CHECK ADD  CONSTRAINT [FK_dbo_AspNetUserLogins_dbo_AspNetUsers_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[AspNetUsers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AspNetUserLogins] CHECK CONSTRAINT [FK_dbo_AspNetUserLogins_dbo_AspNetUsers_UserId]
GO
ALTER TABLE [dbo].[AspNetUserRoles]  WITH CHECK ADD  CONSTRAINT [FK_AspNetUserRoles_AspNetRoles] FOREIGN KEY([AspNetRoles_Id])
REFERENCES [dbo].[AspNetRoles] ([Id])
GO
ALTER TABLE [dbo].[AspNetUserRoles] CHECK CONSTRAINT [FK_AspNetUserRoles_AspNetRoles]
GO
ALTER TABLE [dbo].[AspNetUserRoles]  WITH CHECK ADD  CONSTRAINT [FK_AspNetUserRoles_AspNetUsers] FOREIGN KEY([AspNetUsers_Id])
REFERENCES [dbo].[AspNetUsers] ([Id])
GO
ALTER TABLE [dbo].[AspNetUserRoles] CHECK CONSTRAINT [FK_AspNetUserRoles_AspNetUsers]
GO
ALTER TABLE [dbo].[tb_Capitalflow]  WITH CHECK ADD  CONSTRAINT [FK_tb_Capitalflow_AspNetUsers] FOREIGN KEY([userid])
REFERENCES [dbo].[AspNetUsers] ([Id])
GO
ALTER TABLE [dbo].[tb_Capitalflow] CHECK CONSTRAINT [FK_tb_Capitalflow_AspNetUsers]
GO
ALTER TABLE [dbo].[tb_Capitalflow]  WITH CHECK ADD  CONSTRAINT [FK_tb_Capitalflow_AspNetUsers1] FOREIGN KEY([otherUser])
REFERENCES [dbo].[AspNetUsers] ([Id])
GO
ALTER TABLE [dbo].[tb_Capitalflow] CHECK CONSTRAINT [FK_tb_Capitalflow_AspNetUsers1]
GO
ALTER TABLE [dbo].[tb_Notice]  WITH CHECK ADD  CONSTRAINT [FK_tb_Notice_AspNetUsers] FOREIGN KEY([creator])
REFERENCES [dbo].[AspNetUsers] ([Id])
GO
ALTER TABLE [dbo].[tb_Notice] CHECK CONSTRAINT [FK_tb_Notice_AspNetUsers]
GO
ALTER TABLE [dbo].[tb_UserAccount]  WITH CHECK ADD  CONSTRAINT [FK_tb_UserAccount_AspNetUsers] FOREIGN KEY([Id])
REFERENCES [dbo].[AspNetUsers] ([Id])
GO
ALTER TABLE [dbo].[tb_UserAccount] CHECK CONSTRAINT [FK_tb_UserAccount_AspNetUsers]
GO
ALTER TABLE [dbo].[tb_UserAccount]  WITH CHECK ADD  CONSTRAINT [FK_tb_UserAccount_tb_grade] FOREIGN KEY([MyGrade])
REFERENCES [dbo].[tb_grade] ([id])
GO
ALTER TABLE [dbo].[tb_UserAccount] CHECK CONSTRAINT [FK_tb_UserAccount_tb_grade]
GO
USE [master]
GO
ALTER DATABASE [aspnet-virtual_Currency-20181023095441] SET  READ_WRITE 
GO
