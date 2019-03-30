use AdventureWorks2014;
go
drop database library;
go
--Create a new database for the library tables
CREATE DATABASE LIBRARY;
GO
USE LIBRARY;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

--Create all tables for the library database
CREATE TABLE LIBRARY_BRANCH (
	BranchID INT PRIMARY KEY NOT NULL IDENTITY(1,1),
	BranchName VARCHAR(100) NOT NULL,
	[Address] VARCHAR(150) NOT NULL
);

CREATE TABLE PUBLISHER (
	PublisherName VARCHAR(100) PRIMARY KEY NOT NULL,
	[Address] VARCHAR(150) NOT NULL,
	Phone VARCHAR(15) NOT NULL
);

CREATE TABLE BOOKS (
	BookID INT PRIMARY KEY NOT NULL IDENTITY(1,1),
	Title VARCHAR(200) NOT NULL,
	PublisherName VARCHAR(100) NOT NULL CONSTRAINT fkfPublisherName FOREIGN KEY REFERENCES Publisher(PublisherName) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE BOOK_AUTHORS (
	BookID INT NOT NULL CONSTRAINT fkfBookID1 FOREIGN KEY REFERENCES Books(BookID) ON UPDATE CASCADE ON DELETE CASCADE,
	AuthorName VARCHAR(150) NOT NULL
);

CREATE TABLE BOOK_COPIES (
	BookID INT NOT NULL CONSTRAINT fkfBookID2 FOREIGN KEY REFERENCES Books(BookID) ON UPDATE CASCADE ON DELETE CASCADE,
	BranchID INT NOT NULL CONSTRAINT fkfBranchID1 FOREIGN KEY REFERENCES Library_Branch(BranchID) ON UPDATE CASCADE ON DELETE CASCADE,
	Number_Of_Copies INT NOT NULL
);

CREATE TABLE BORROWER (
	CardNo INT PRIMARY KEY NOT NULL IDENTITY(1000,1),
	Name VARCHAR(100) NOT NULL,
	[Address] VARCHAR(150) NOT NULL,
	Phone VARCHAR(15) NOT NULL,
	CONSTRAINT ukCardName UNIQUE (CardNo, Name)
);

CREATE TABLE BOOK_LOANS (
	BookID INT NOT NULL CONSTRAINT fkfBookID3 FOREIGN KEY REFERENCES Books(BookID) ON UPDATE CASCADE ON DELETE CASCADE,
	BranchID INT NOT NULL CONSTRAINT fkfBranchID2 FOREIGN KEY REFERENCES Library_Branch(BranchID) ON UPDATE CASCADE ON DELETE CASCADE,
	CardNo INT NOT NULL CONSTRAINT fkfcardNo1 FOREIGN KEY REFERENCES Borrower(CardNo) ON UPDATE CASCADE ON DELETE CASCADE,
	DateOut DATE NOT NULL,
	DateDue DATE NOT NULL
);
go

--Stored procedure to insert books and authors
CREATE procedure [NewBook]
	@Title VARCHAR(200),
	@AuthorName VARCHAR(150),
	@PublisherName VARCHAR(100)

as
begin
	declare @BookID INT;
	declare @Check INT;

	set @Check = (select count(*) from BOOKS where Title = @Title and PublisherName = @PublisherName)

	if @Check = 0
		begin
			INSERT INTO BOOKS (Title, PublisherName)
			VALUES (@Title, @PublisherName);

			set @BookID = (select max(BookID) from BOOKS where Title = @Title and PublisherName = @PublisherName);

			INSERT INTO BOOK_AUTHORS (BookID, AuthorName)
			VALUES (@BookID, @AuthorName);
		end

end;
go

--Stored procedure to insert loan and borrower records together
CREATE procedure [NewBookLoan]
	@BookID INT = NULL,
	@BranchID INT = NULL,
	@DateOut DATE = NULL,
	@Name VARCHAR(100),
	@Address VARCHAR(150),
	@Phone VARCHAR(15)

as
begin
	declare @CopiesAtBranch INT;
	declare @CopiesCheckedOut INT;
	declare @CardNo INT;

	set @CopiesAtBranch = (select sum(Number_Of_Copies) from BOOK_COPIES where BookID = @BookID and BranchID = @BranchID);
	set @CopiesCheckedOut = (select count(*) from BOOK_LOANS where BookID = @BookID and BranchID = @BranchID);
	set @CardNo = (select distinct CardNo from BORROWER where Name = @Name and [Address] = @Address and phone = @Phone);

	if @CardNo is NULL
		begin
			INSERT INTO BORROWER (Name, [Address], Phone)
			VALUES (@Name, @Address, @Phone);

			set @CardNo = (select distinct CardNo from BORROWER where Name = @Name and [Address] = @Address and phone = @Phone);
		end
	if @BookID is not null
		begin
			if isnull(@CopiesAtBranch,0) - isnull(@CopiesCheckedOut,0) <= 0
				begin
					raiserror('No copies currently available at branch to loan',16,1)
					return
				end
			else
				begin
					INSERT INTO BOOK_LOANS (BookID, BranchID, CardNo, DateOut, DateDue)
					VALUES (@BookID, @BranchID, @CardNo, @DateOut, dateadd(d,45,@DateOut));
				end
		end
end;
go

--Populate tables with data
INSERT INTO LIBRARY_BRANCH (BranchName, [Address])
VALUES ('Sharpstown','627 North Shark Ave'),
	('Central','112211 Middleton Street'),
	('Wrigley','8023 Chicago Lane'),
	('Georgetown','600 Mountain Way');

INSERT INTO PUBLISHER (PublisherName, [Address], Phone)
VALUES ('Picador USA','New York, NY','(800) 221-7945'),
	('Tor Books','New York, NY','(800) 526-2357'),
	('Anchor Books','New York, NY','(800) 294-2847'),
	('Macmillon Publishers','London, England','(800) 803-9834'),
	('Bloomsbury','London, England','(800) 203-0923'),
	('Louisiana State University Press','Baton Rouge, LA','(800) 924-2093'),
	('Penguin Books','London, England','(800) 590-4999'),
	('The Mountaineers Books','Seattle, WA','(206) 223-6303');

EXEC NewBook 'The Lost Tribe', 'Mark Lee', 'Picador USA';
EXEC NewBook 'East of Eden', 'John Stiebeck', 'Penguin Books';
EXEC NewBook 'The Way of Kings', 'Brandon Sanderson', 'Tor Books';
EXEC NewBook 'Words of Radiance','Brandon Sanderson', 'Tor Books';
EXEC NewBook 'Oathbringer','Brandon Sanderson', 'Tor Books';
EXEC NewBook 'Ghost Soldiers', 'Hampton Side', 'Anchor Books';
EXEC NewBook 'Winter Garden', 'Kristin Hannah', 'Macmillon Publishers';
EXEC NewBook 'The Stand', 'Stephen King', 'Penguin Books';
EXEC NewBook 'It', 'Stephen King', 'Penguin Books';
EXEC NewBook 'Harry Potter and the Sorcerers Stone', 'J.K. Rowling', 'Bloomsbury';
EXEC NewBook 'Harry Potter and the Chamber of Secrets', 'J.K. Rowling', 'Bloomsbury';
EXEC NewBook 'Harry Potter and the Prisoner of Azkaban', 'J.K. Rowling', 'Bloomsbury';
EXEC NewBook 'Harry Potter and the Goblet of Fire', 'J.K. Rowling', 'Bloomsbury';
EXEC NewBook 'Harry Potter and the Order of the Phoenix', 'J.K. Rowling', 'Bloomsbury';
EXEC NewBook 'Harry Potter and the Half-Blood Prince', 'J.K. Rowling', 'Bloomsbury';
EXEC NewBook 'Harry Potter and the Deathly Hallows', 'J.K. Rowling', 'Bloomsbury';
EXEC NewBook 'Confederacy of Dunces', 'John Kennedy Toole', 'Louisiana State University Press';
EXEC NewBook 'Pillars of the Earth', 'Ken Follett', 'Macmillon Publishers';
EXEC NewBook 'The Healing of America', 'T.R. Reid', 'Penguin Books';
EXEC NewBook 'Staying Alive in Avalanche Terrain', 'Bruce Termper', 'The Mountaineers Books';

INSERT INTO BOOK_COPIES (BookID, BranchID, Number_Of_Copies)
VALUES
(1,1,4),(1,2,2),(1,3,2),(1,4,2),
(2,1,2),(2,2,3),(2,3,2),(2,4,2),
(3,1,3),(3,2,5),(3,3,2),(3,4,2),
(4,1,3),(4,2,5),(4,3,2),(4,4,2),
(5,1,3),(5,2,5),(5,4,2),
(6,1,2),(6,2,3),(6,4,3),
(7,1,3),(7,2,3),(7,3,2),(7,4,2),
(8,1,5),(8,2,3),(8,3,2),(8,4,2),
(9,1,3),(9,2,2),(9,3,3),(9,4,2),
(10,1,6),(10,2,6),(10,3,6),(10,4,6),
(11,1,6),(11,2,6),(11,3,6),(11,4,6),
(12,1,6),(12,2,6),(12,3,6),(12,4,6),
(13,1,6),(13,2,6),(13,3,6),(13,4,6),
(14,1,6),(14,2,6),(14,3,6),(14,4,6),
(15,1,6),(15,2,6),(15,3,6),(15,4,6),
(16,1,6),(16,2,6),(16,3,6),(16,4,6),
(17,1,2),(17,3,2),(17,4,2),
(18,1,3),(18,2,2),(18,3,2),(18,4,2),
(19,1,2),(19,2,2),(19,3,2),
(20,2,4),(20,3,2),(20,4,2);

EXEC NewBookLoan 3, 2, '12-10-2018', 'Gary Lewis','203 Trumble Street','(239) 209-6094';
EXEC NewBookLoan 4, 2, '12-10-2018', 'Gary Lewis','203 Trumble Street','(239) 209-6094';
EXEC NewBookLoan 5, 2, '12-10-2018', 'Gary Lewis','203 Trumble Street','(239) 209-6094';
EXEC NewBookLoan 15, 2, '12-10-2018', 'Gary Lewis','203 Trumble Street','(239) 209-6094';
EXEC NewBookLoan 16, 2, '12-10-2018', 'Gary Lewis','203 Trumble Street','(239) 209-6094';
EXEC NewBookLoan 19, 2, '12-10-2018', 'Gary Lewis','203 Trumble Street','(239) 209-6094';
EXEC NewBookLoan 20, 2, '12-10-2018', 'Gary Lewis','203 Trumble Street','(239) 209-6094';
EXEC NewBookLoan 1, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 8, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 9, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 10, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 11, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 12, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 13, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 14, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 15, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 16, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 18, 1, '12-10-2018', 'Judy Falcon','30495 Tyler Ave','(234) 595-9083';
EXEC NewBookLoan 2, 4, '12-12-2018', 'Mike Lambert','883 East Ave','(239) 389-3984';
EXEC NewBookLoan 6, 4, '12-12-2018', 'Mike Lambert','883 East Ave','(239) 389-3984';
EXEC NewBookLoan 17, 4, '12-12-2018', 'Mike Lambert','883 East Ave','(239) 389-3984';
EXEC NewBookLoan 6, 2, '12-13-2018', 'Tim Smith','40 Peacock Road','(239) 777-3484';
EXEC NewBookLoan 10, 2, '12-13-2018', 'Tim Smith','40 Peacock Road','(239) 777-3484';
EXEC NewBookLoan 3, 3, '12-19-2018', 'Kelly Pisnik','634 East Ave','(239) 389-5675';
EXEC NewBookLoan 7, 3, '12-19-2018', 'Kelly Pisnik','634 East Ave','(239) 389-5675';
EXEC NewBookLoan 8, 3, '12-19-2018', 'Kelly Pisnik','634 East Ave','(239) 389-5675';
EXEC NewBookLoan 13, 3, '12-19-2018', 'Kelly Pisnik','634 East Ave','(239) 389-5675';
EXEC NewBookLoan 19, 3, '12-19-2018', 'Kelly Pisnik','634 East Ave','(239) 389-5675';
EXEC NewBookLoan 1, 4, '12-23-2018', 'Scott Watcher','998 Yax Drive','(234) 593-0934';
EXEC NewBookLoan 2, 4, '12-23-2018', 'Scott Watcher','998 Yax Drive','(234) 593-0934';
EXEC NewBookLoan 7, 1, '12-23-2018', 'Penny Tepet','5656 Bowlish Street','(239) 665-3948';
EXEC NewBookLoan 4, 3, '12-28-2018', 'George Yanny','32 Peacock Road','(234) 343-3459';
EXEC NewBookLoan 10, 3, '12-28-2018', 'George Yanny','32 Peacock Road','(234) 343-3459';
EXEC NewBookLoan 17, 3, '12-28-2018', 'George Yanny','32 Peacock Road','(234) 343-3459';
EXEC NewBookLoan 18, 3, '12-28-2018', 'George Yanny','32 Peacock Road','(234) 343-3459';
EXEC NewBookLoan 5, 1, '12-29-2018', 'Laura King','345 Teatree Lane','(239) 555-2342';
EXEC NewBookLoan 7, 1, '12-29-2018', 'Laura King','345 Teatree Lane','(239) 555-2342';
EXEC NewBookLoan 11, 1, '12-29-2018', 'Laura King','345 Teatree Lane','(239) 555-2342';
EXEC NewBookLoan 16, 1, '12-29-2018', 'Laura King','345 Teatree Lane','(239) 555-2342';
EXEC NewBookLoan 17, 1, '12-29-2018', 'Laura King','345 Teatree Lane','(239) 555-2342';
EXEC NewBookLoan 1, 2, '01-03-2019', 'Susan Halton','345 Filler Street','(234) 545-5671';
EXEC NewBookLoan 4, 2, '01-03-2019', 'Susan Halton','345 Filler Street','(234) 545-5671';
EXEC NewBookLoan 6, 2, '01-03-2019', 'Susan Halton','345 Filler Street','(234) 545-5671';
EXEC NewBookLoan 9, 2, '01-03-2019', 'Susan Halton','345 Filler Street','(234) 545-5671';
EXEC NewBookLoan 15, 2, '01-03-2019', 'Susan Halton','345 Filler Street','(234) 545-5671';
EXEC NewBookLoan 18, 2, '01-03-2019', 'Susan Halton','345 Filler Street','(234) 545-5671';
EXEC NewBookLoan 6, 4, '01-11-2019', 'John Black','676 Tabletop Ave','(234) 545-8888';
EXEC NewBookLoan 7, 4, '01-11-2019', 'John Black','676 Tabletop Ave','(234) 545-8888';
EXEC NewBookLoan 14, 4, '01-11-2019', 'John Black','676 Tabletop Ave','(234) 545-8888';
EXEC NewBookLoan 20, 4, '01-11-2019', 'John Black','676 Tabletop Ave','(234) 545-8888';
EXEC NewBookLoan NULL, NULL, NULL, 'Janet Black','676 Tabletop Ave','(234) 545-8888';
EXEC NewBookLoan NULL, NULL, NULL, 'Toby Petty','6676 Ash Street','(234) 776-3498';
EXEC NewBookLoan NULL, NULL, NULL, 'Joe Carpenter','884 Washington Lane','(239) 830-4598';
EXEC NewBookLoan NULL, NULL, NULL, 'Dan Miller','6040 Lake Mills Road','(234) 459-3400';
go


--Create stored procedures to answer Project Questions #1-7
/*
Returns # of copies of books with a given title at a given library branch
  - If NULL title is passed, returns number of copies for each title that the given branch owns
  - If NULL branch is passed, returns number of copies for given title at each branch
*/
CREATE procedure [dbo].[TitleCopiesAtBranch] 
	@Title varchar(200) = NULL,
	@BranchName varchar(100) = NULL

as
begin
	declare @errorstring varchar(100);
	declare @errorstring1 varchar(100);
	declare @results1 int;

	set @errorstring1 = 'There is no branch called ''' + @branchName + '''.';

	begin try
		set @results1 = (select count(*) from LIBRARY_BRANCH where BranchName = isnull(@BranchName,BranchName));

		if @results1 = 0
			begin
				raiserror(@errorstring1,16,1)
				return
			end	
		else
			begin	
				select BranchName + ' owns ' + cast(isnull(sum(Number_Of_Copies),0) as varchar(5)) + ' copies of ' + Title
				from BOOKS b 
					left join BOOK_COPIES c on c.BookID = b.BookID
					left join LIBRARY_BRANCH l on c.BranchID = l.BranchID
				where Title = isnull(@Title, Title)
					and BranchName = isnull(@BranchName, BranchName)
				group by BranchName, Title;
			end
	end try

	begin catch
		select @errorstring = error_message()
		raiserror (@errorstring,10,1);
	end catch

end;
go

exec [TitleCopiesAtBranch] 'The Lost Tribe', 'Sharpstown';
exec [TitleCopiesAtBranch] 'The Lost Tribe', NULL;
go


/*
Returns the names of all borrowers who do not have any books checked out
*/
CREATE procedure [dbo].[BorrowersNoBooks] 

as
begin
	declare @errorstring varchar(100);

	begin try
		select Name as [Borrowers without books checked out]
		from BORROWER b 
			left join BOOK_LOANS l on b.CardNo = l.CardNo
		where l.cardno is null;
	end try

	begin catch
		select @errorstring = error_message()
		raiserror (@errorstring,10,1);
	end catch

end;
go

exec [BorrowersNoBooks];
go


/*
Returns title, borrower name, and address for each book that is due today at given branch
  - If NULL branch is passed, returns books due today at all branches
*/
CREATE procedure [dbo].[BooksDueToday] 
	@BranchName varchar(100) = NULL

as
begin
	declare @errorstring varchar(100);
	declare @errorstring1 varchar(100);
	declare @results1 int;

	set @errorstring1 = 'There is no branch called ''' + @branchName + '''.';

	begin try
		set @results1 = (select count(*) from LIBRARY_BRANCH where BranchName = isnull(@BranchName,BranchName));

		if @results1 = 0
			begin
				raiserror(@errorstring1,16,1)
				return
			end	
		else
			begin	
				select BranchName + ': ' + b.Title + ' is due today, checked out by ' + bo.Name + ' (' + bo.[Address] + ')'
				from BOOK_LOANS lo 
					left join BOOKS b on b.BookID = lo.BookID
					left join LIBRARY_BRANCH l on lo.BranchID = l.BranchID
					left join BORROWER bo on lo.cardno = bo.cardno
				where DateDue = cast(getdate() as date)
					and BranchName = isnull(@BranchName, BranchName)
				group by BranchName, b.Title, bo.Name, bo.[Address];
			end
	end try

	begin catch
		select @errorstring = error_message()
		raiserror (@errorstring,10,1);
	end catch

end;
go

exec [BooksDueToday] 'Sharpstown';
--exec [BooksDueToday] NULL;
go

/*
Returns # of books loaned out at given branch
  - If NULL branch is given, gives @ of books loaned out for each branch
*/
CREATE procedure [dbo].[BooksLoanedAtBranch] 
	@BranchName varchar(100) = NULL

as
begin
	declare @errorstring varchar(100);
	declare @errorstring1 varchar(100);
	declare @results1 int;

	set @errorstring1 = 'There is no branch called ''' + @branchName + '''.';

	begin try
		set @results1 = (select count(*) from LIBRARY_BRANCH where BranchName = isnull(@BranchName,BranchName));

		if @results1 = 0
			begin
				raiserror(@errorstring1,16,1)
				return
			end	
		else
			begin	
				select BranchName, count(distinct lo.cardno) [Books Checked Out]
				from BOOK_LOANS lo 
					left join BOOKS b on b.BookID = lo.BookID
					left join LIBRARY_BRANCH l on lo.BranchID = l.BranchID
					left join BORROWER bo on lo.cardno = bo.cardno
				where BranchName = isnull(@BranchName, BranchName)
				group by BranchName;
			end
	end try

	begin catch
		select @errorstring = error_message()
		raiserror (@errorstring,10,1);
	end catch

end;
go

--exec [BooksLoanedAtBranch] 'Sharpstown';
exec [BooksLoanedAtBranch] NULL;
go

/*
Returns borrowers, their address, and number of books loaned out for anyone who has more than 5 books loaned to them
*/
CREATE procedure [dbo].[PeopleLoanedOver5Books] 

as
begin
	declare @errorstring varchar(100);

	begin try
		select b.Name, b.[Address] , count(distinct l.cardno) NumberOfBooksCheckedOut 
		from BOOK_LOANS l
			join BORROWER b on l.CardNo = b.CardNo
		group by b.name, b.[Address]
		having count(distinct l.cardno) > 5;
	end try

	begin catch
		select @errorstring = error_message()
		raiserror (@errorstring,10,1);
	end catch

end;
go

exec [PeopleLoanedOver5Books];
go

/*
Returns # of copies of books with a given author at a given library branch
  - If NULL author is passed, returns number of copies for each author that the given branch owns
  - If NULL branch is passed, returns number of copies for given author at each branch
*/
CREATE procedure [dbo].[AuthorCopiesAtBranch] 
	@AuthorName varchar(150) = NULL,
	@BranchName varchar(100) = NULL

as
begin
	declare @errorstring varchar(100);
	declare @errorstring1 varchar(100);
	declare @results1 int;

	set @errorstring1 = 'There is no branch called ''' + @branchName + '''.';

	begin try
		set @results1 = (select count(*) from LIBRARY_BRANCH where BranchName = isnull(@BranchName,BranchName));

		if @results1 = 0
			begin
				raiserror(@errorstring1,16,1)
				return
			end	
		else
			begin	
				select BranchName, AuthorName, Title, Number_Of_Copies
				from BOOKS b 
					join BOOK_AUTHORS a on b.BookID = a.BookID
					left join BOOK_COPIES c on c.BookID = b.BookID
					left join LIBRARY_BRANCH l on c.BranchID = l.BranchID
				where AuthorName = isnull(@AuthorName, AuthorName)
					and BranchName = isnull(@BranchName, BranchName);
			end
	end try

	begin catch
		select @errorstring = error_message()
		raiserror (@errorstring,10,1);
	end catch

end;
go

exec [AuthorCopiesAtBranch] 'Stephen King', 'Central';
--exec [AuthorCopiesAtBranch] 'Stephen King', NULL;
--exec [AuthorCopiesAtBranch] NULL, 'Central';
go