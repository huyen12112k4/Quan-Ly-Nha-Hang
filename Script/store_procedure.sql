USE QLNHAHANG
GO
--PROCEDURE phân hệ ChiNhanh -- sửa lại các sp có mã thuc đơn thành mã khu vực
GO
CREATE PROCEDURE THEM_CHI_NHANH @MACHINHANH TINYINT,@TENCHINHANH NVARCHAR(100), @DIACHI NVARCHAR(255), @THOIGIANMOCUA TIME, @THOIGIANDONGCUA TIME, @SDT VARCHAR(10), @BAIDOXEHOI BIT, @BAIDOXEMAY BIT, @NVQL CHAR(6), @MAKV TINYINT, @GIAOHANG BIT
AS
BEGIN
	IF(@BAIDOXEHOI!=0 OR @BAIDOXEHOI!=1)
		BEGIN
			RAISERROR(N'Giá trị của thuộc tính bãi đỗ xe hơi chỉ là 0 hoặc 1',16,1)
		END
	ELSE
		BEGIN
			IF(@BAIDOXEMAY!=0 OR @BAIDOXEMAY!=1)
				BEGIN
					RAISERROR(N'Giá trị của thuộc tính bãi đỗ xe máy chỉ là 0 hoặc 1',16,1)
				END
			ELSE
				BEGIN
					IF EXISTS (SELECT 1 FROM NhanVien AS NV WHERE NV.MaNhanVien=@NVQL)
						BEGIN
							IF(@GIAOHANG!=0 OR @GIAOHANG!=1)
								BEGIN
									RAISERROR(N'Giá trị của thuộc tính giao hàng chỉ có thể là 0 hoặc 1',16,1)
								END
							ELSE
								IF(@THOIGIANMOCUA<@THOIGIANDONGCUA)
									BEGIN
										IF EXISTS (SELECT 1 FROM KhuVuc WHERE MaKhuVuc=@MAKV)
											BEGIN
												INSERT INTO ChiNhanh(MaChiNhanh, TenChiNhanh, DiaChi, ThoiGianMoCua, ThoiGianDongCua, SoDienThoai, BaiDoXeHoi, BaiDoXeMay, NhanVienQuanLy, MaKhuVuc, GiaoHang) values (@MACHINHANH, @TENCHINHANH, @DIACHI, @THOIGIANMOCUA, @THOIGIANDONGCUA, @SDT, @BAIDOXEHOI, @BAIDOXEMAY, @NVQL, @MAKV, @GIAOHANG)
											END
										ELSE
											BEGIN
												RAISERROR(N'Không tìm thấy mã khu vực',16,1)
											END
									END
								ELSE
									BEGIN
										RAISERROR(N'Thời gian mở cửa phải trước thời gian đóng cửa',16,1)
									END
								
						END
					ELSE
						BEGIN
							RAISERROR(N'Không tìm thấy nhân viên quản lý phù hợp',16,1)
						END
				END
		END
END
GO

CREATE PROCEDURE XOA_CHINHANH @MACHINHANH TINYINT
AS
BEGIN
	BEGIN TRY
			DELETE FROM DatCho WHERE MaChiNhanh = @MaChiNhanh;
			DELETE FROM Ban WHERE MaChiNhanh = @MaChiNhanh;
			DELETE FROM LichSuLamViec WHERE MaChiNhanh = @MaChiNhanh;
			DELETE FROM PhucVu WHERE MaChiNhanh = @MaChiNhanh;
			DELETE FROM PhieuDatMon WHERE MaChiNhanh = @MaChiNhanh;
			DELETE FROM DatTruoc WHERE MaChiNhanh = @MaChiNhanh;

			-- Cuối cùng, xóa chi nhánh
			DELETE FROM ChiNhanh WHERE MaChiNhanh = @MaChiNhanh;

			PRINT N'Xóa chi nhánh thành công'
	END TRY
	BEGIN CATCH
		PRINT 'Đã xảy ra lỗi. Giao dịch bị hủy.';
        ROLLBACK;
        THROW
    END CATCH
END
GO


GO
CREATE PROCEDURE CAPNHAT_CHINHANH @MACHINHANH TINYINT, @TENCHINHANH NVARCHAR(100),@DiaChi NVARCHAR(255), @ThoiGianMoCua TIME, @ThoiGianDongCua TIME, @SoDienThoai VARCHAR(10), @BaiDoXeHoi BIT, @BaiDoXeMay BIT, @NhanVienQuanLy CHAR(6), @MaKhuVuc TINYINT, @GiaoHang BIT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM ChiNhanh WHERE MaChiNhanh = @MaChiNhanh)
		BEGIN
			RAISERROR(N'Chi nhánh không tồn tại',16,1)
		END
	ELSE
		BEGIN
			UPDATE ChiNhanh
				SET 
					TenChiNhanh = COALESCE(@TenChiNhanh, TenChiNhanh),
					DiaChi = COALESCE(@DiaChi, DiaChi),
					ThoiGianMoCua = COALESCE(@ThoiGianMoCua, ThoiGianMoCua),
					ThoiGianDongCua = COALESCE(@ThoiGianDongCua, ThoiGianDongCua),
					SoDienThoai = COALESCE(@SoDienThoai, SoDienThoai),
					BaiDoXeHoi = COALESCE(@BaiDoXeHoi, BaiDoXeHoi),
					BaiDoXeMay = COALESCE(@BaiDoXeMay, BaiDoXeMay),
					NhanVienQuanLy = COALESCE(@NhanVienQuanLy, NhanVienQuanLy),
					MaKhuVuc = COALESCE(@MaKhuVuc, MaKhuVuc),
					GiaoHang = COALESCE(@GiaoHang, GiaoHang)
				WHERE MaChiNhanh = @MaChiNhanh;

    PRINT 'Cập nhật thông tin chi nhánh thành công.';
		END
END
GO

GO
CREATE PROCEDURE THONGKE_DOANHTHU_CHINHANH (@MACN TINYINT, @START_DAY DATE, @END_DAY DATE)
AS
BEGIN
	DECLARE @SLCN INT, @SLP INT, @SLHD INT, @DT DECIMAL(18,3)

	SELECT @SLCN=COUNT(*)
	FROM ChiNhanh AS CN

	SELECT @SLP=COUNT(*)
	FROM PhieuDatMon AS P

	SELECT @SLHD=COUNT(*)
	FROM HoaDon AS HD

	IF(@SLCN!=0)
		BEGIN
			IF(@SLP!=0)
				BEGIN
					IF(@SLHD!=0)
						BEGIN
							IF EXISTS (SELECT 1 FROM ChiNhanh AS CN WHERE CN.MaChiNhanh=@MACN)
								BEGIN
										SELECT @DT=ISNULL(SUM(HD.ThanhTien), 0)
										FROM ChiNhanh AS CN
										JOIN PhieuDatMon AS P ON P.MaChiNhanh=CN.MaChiNhanh
										JOIN HoaDon AS HD ON HD.MaPhieu=P.MaPhieu
										WHERE HD.NgayLap BETWEEN @START_DAY AND @END_DAY AND CN.MaChiNhanh=@MACN

										PRINT 'Doanh thu của chi nhánh từ ' +  CAST(@START_DAY AS NVARCHAR) + ' đến ' + CAST(@END_DAY AS NVARCHAR) + ' là: ' + CAST(@DT AS NVARCHAR);

								END
							ELSE
								BEGIN
									RAISERROR(N'Không tìm thấy mã chi nhánh',16,1)
								END
						END
					ELSE
						BEGIN
							RAISERROR(N'Không có dữ liệu trong bảng hóa đơn',16,1)
						END
				END
			ELSE
				BEGIN
					RAISERROR(N'Không có dữ liệu trong bảng phiếu đặt món',16,1)
				END
		END
	ELSE
		BEGIN
			RAISERROR(N'Không có dữ liệu trong bảng chi nhánh',16,1)
		END	

END
GO


GO
CREATE PROCEDURE THONGKE_DOANHTHU_KHUVUC @MAKHUVUC TINYINT, @START_DAY DATE, @END_DAY DATE
AS
BEGIN
	IF EXISTS (SELECT 1 FROM KhuVuc AS KV WHERE KV.MaKhuVuc=@MAKHUVUC)
		BEGIN
			DECLARE @DT DECIMAL(18,3)
			SELECT @DT=SUM(HD.ThanhTien)
			FROM ChiNhanh AS CN
			JOIN PhieuDatMon AS P ON P.MaChiNhanh=CN.MaChiNhanh
			JOIN HoaDon AS HD ON HD.MaPhieu=P.MaPhieu
			WHERE CN.MaKhuVuc=@MAKHUVUC AND HD.NgayLap BETWEEN @START_DAY AND @END_DAY

			PRINT N'Tổng doanh thu khu vực cần tìm: '  +  CAST(@DT AS NVARCHAR)
		END
	ELSE
		BEGIN
			RAISERROR(N'Không tìm thấy mã khu vực',16,1)
		END
END
GO


GO
CREATE PROCEDURE DIEUDONG_QUANLI @MACN TINYINT, @NVQL CHAR(6)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM ChiNhanh AS CN WHERE CN.MaChiNhanh=@MACN)
		BEGIN
			IF EXISTS (SELECT 1 FROM NhanVien AS NV WHERE NV.MaNhanVien=@NVQL)
				BEGIN
					UPDATE ChiNhanh SET NhanVienQuanLy=@NVQL WHERE MaChiNhanh=@MACN
				END
			ELSE
				BEGIN
					RAISERROR(N'Không tìm thấy nhân viên phù hợp',16,1)
				END
		END
	ELSE
		BEGIN
			RAISERROR(N'Không tìm thấy mã chi nhánh',16,1)
		END
	
END
GO


drop proc THEM_MON
CREATE PROCEDURE THEM_MON  @MAMUC TINYINT, @TENMON NVARCHAR(100), @GIAHIENTAI DECIMAL(18,3), @GIAOHANG BIT, @ANHMON  VARBINARY(MAX)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Mon AS M WHERE M.TenMon=@TENMON)
		BEGIN
			IF EXISTS(SELECT 1 FROM MucThucDon AS M WHERE M.MaMuc=@MAMUC)
				BEGIN
					IF(@GIAOHANG != 0 AND  @GIAOHANG != 1)
						BEGIN
							RAISERROR(N'Thuộc tính GiaoHang chỉ được nhận 2 giá trị là 0 hoặc 1',16,1)
						END
					ELSE
						BEGIN
							IF(@GIAHIENTAI>0)
								BEGIN
									if (@ANHMON IS NULL)
										INSERT INTO MON(MaMuc, TenMon, GiaHienTai, GiaoHang) VALUES (@MAMUC, @TENMON, @GIAHIENTAI, @GIAOHANG)
									else
										INSERT INTO MON(MaMuc, TenMon, GiaHienTai, GiaoHang, AnhMon) VALUES (@MAMUC, @TENMON, @GIAHIENTAI, @GIAOHANG, @ANHMON)
								END
							ELSE
								BEGIN
									RAISERROR(N'Giá món phải lớn hơn 0',16,1);
								END
						END
				END
			ELSE
				BEGIN
					RAISERROR(N'Không tìm thấy mục thực đơn',16,1)
				END
		END
	ELSE
		BEGIN
			RAISERROR(N'Mã món ăn đã bị trùng',16,1)
		END
END
GO


CREATE PROCEDURE THEMMON_VAOTHUCDON @MATHUCDON TINYINT, @MAMON SMALLINT
AS
BEGIN
	IF EXISTS(SELECT 1 FROM ThucDon AS TD WHERE TD.MaThucDon=@MATHUCDON)
		BEGIN
			IF EXISTS(SELECT 1 FROM Mon AS M WHERE M.MaMon=@MAMON)
				BEGIN
					DELETE FROM ThucDon_Mon WHERE MaThucDon=@MATHUCDON AND MaMon=@MAMON
				END
			ELSE
				BEGIN
					RAISERROR(N'Không tìm thấy món phù hợp',16,1)
				END
		END
	ELSE
		BEGIN
			RAISERROR(N'Không tìm thấy mã thực đơn phù hợp',16,1)
		END
END
GO



CREATE PROCEDURE XOAMON_KHOITHUCDON @MATHUCDON TINYINT, @MAMON SMALLINT
AS
BEGIN
	IF EXISTS(SELECT 1 FROM ThucDon AS TD WHERE TD.MaThucDon=@MATHUCDON)
		BEGIN
			IF EXISTS(SELECT 1 FROM Mon AS M WHERE M.MaMon=@MAMON)
				BEGIN
					INSERT INTO ThucDon_Mon (MaThucDon, MaMon) VALUES (@MATHUCDON, @MAMON)
				END
			ELSE
				BEGIN
					RAISERROR(N'Không tìm thấy món phù hợp',16,1)
				END
		END
	ELSE
		BEGIN
			RAISERROR(N'Không tìm thấy mã thực đơn phù hợp',16,1)
		END
END
GO






								


							
--Store procedure PHÂN HỆ NHÂN VIÊN SP  TẠO PHIẾU ĐẶT MÓN
CREATE PROC THEMPDM
	@NhanVienLap CHAR(6),
	@MaSoBan CHAR(2),
	@MaKhachHang BIGINT,
	@MaChiNhanh TINYINT
AS
BEGIN
	--Kiểm tra nhân viên có tồn tại không
	IF NOT EXISTS (SELECT 1
	FROM NhanVien
	WHERE MaNhanVien = @NhanVienLap
	)
	BEGIN
		RAISERROR (N'Mã nhân viên nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;
	--Kiểm tra mã số bàn có tồn tại không
	IF NOT EXISTS (SELECT 1
	FROM Ban
	WHERE MaSoBan = @MaSoBan
	)
	BEGIN
		RAISERROR (N'Mã bàn nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;
	--Kiểm tra mã khách hàng có tồn tại không
	IF @MaKhachHang IS NOT NULL AND NOT EXISTS (SELECT 1
	FROM KhachHang
	WHERE MaKhachHang = @MaKhachHang
	)
	BEGIN
		RAISERROR (N'Mã khách hàng nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;
	 -- Kiểm tra mã chi nhánh
    IF NOT EXISTS (SELECT 1 FROM ChiNhanh WHERE MaChiNhanh = @MaChiNhanh)
    BEGIN
        RAISERROR (N'Mã chi nhánh nhập vào không tồn tại trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

	
	INSERT INTO PhieuDatMon
	VALUES (GETDATE(),@NhanVienLap, @MaSoBan, @MaKhachHang,@MaChiNhanh);
	
END
GO



--SP CẬP NHẬT PHIẾU ĐẶT MÓN: CHỈNH SỬA SỐ LƯỢNG VÀ GHI CHÚ MÓN, KHÔNG ĐƯỢC XÓA
CREATE PROC NVSUAPDM
	@MaPhieu BIGINT,
	@MaMon TINYINT,
	@SoLuong TINYINT,
	@GhiChu NVARCHAR(200)
AS
BEGIN
	--Kiểm tra mã phiếu có tồn tại chưa
	IF NOT EXISTS (SELECT 1
	FROM PhieuDatMon
	WHERE MaPhieu = @MaPhieu
	)
	BEGIN
		RAISERROR (N'Mã phiếu đặt món nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;
	--Kiểm tra mã món có tồn tại trong chi nhánh đó không
	IF NOT EXISTS (SELECT 1
	FROM PhucVu p
	WHERE p.MaMon = @MaMon AND p.MaChiNhanh  = 
	(SELECT MaChiNhanh
	FROM LichSuLamViec l
	WHERE l.NgayKetThuc IS NULL AND l.MaNhanVien = 
	(SELECT NhanVienLap
	FROM PhieuDatMon d
	WHERE d.MaPhieu = @MaPhieu)
	))
	BEGIN
		RAISERROR (N'Mã món ăn nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;
	--Số lượng phải lớn hơn không
	IF @SoLuong <= 0
	BEGIN
		RAISERROR (N'Số lượng món nhập vào phải lớn hơn không',16,1);
		RETURN;
	END;

	--insert
	-- Insert or Update logic
	IF EXISTS (
		SELECT 1 
		FROM ChiTietPhieu
		WHERE MaPhieu = @MaPhieu AND MaMon = @MaMon
	)
	BEGIN
		-- Update existing record
		UPDATE ChiTietPhieu
		SET SoLuong = @SoLuong, GhiChu = @GhiChu
		WHERE MaPhieu = @MaPhieu AND MaMon = @MaMon;
	END
	ELSE
	BEGIN
		-- Insert new record
		INSERT INTO ChiTietPhieu ( MaMon, SoLuong, GhiChu)
		VALUES (@MaMon, @SoLuong, @GhiChu);
	END;
	
END;
GO

--SP XEM PDM THEO MÃ PDM
CREATE FUNCTION THEODOIPDM (@MaPhieu BIGINT)
RETURNS @KETQUA TABLE (MAPHIEU BIGINT, NGAYLAP DATETIME, NHANVIENLAP CHAR(6), MASOBAN CHAR(2), MAKHACHHANG BIGINT)
AS
BEGIN
	INSERT INTO @KETQUA  (MAPHIEU, NGAYLAP, NHANVIENLAP , MASOBAN , MAKHACHHANG )
	SELECT MaPhieu, NgayLap, NhanVienLap, MaSoBan, MaKhachHang
	FROM PhieuDatMon
	WHERE MaPhieu = @MaPhieu

	RETURN;
END;
GO




--SP TẠO HÓA ĐƠN DỰA VÀO MÃ PDM
CREATE PROC TAOHOADON
	@MaPhieu BIGINT
AS
BEGIN
	--Kiểm tra mã phiếu đầu vào
	IF NOT EXISTS (SELECT 1
	FROM PhieuDatMon
	WHERE MaPhieu= @MaPhieu
	)
	BEGIN
		RAISERROR (N'Mã phiếu nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;
	--Tạo các thông tin cho HÓA ĐƠN
	DECLARE @TongTien DECIMAL(10, 2)
    DECLARE @GiamGia DECIMAL(5, 2)
    DECLARE @ThanhTien DECIMAL(10, 2)

	SET @TongTien = 
	(SELECT SUM(m.GiaHienTai * c.SoLuong)
	 FROM ChiTietPhieu c INNER JOIN Mon m ON m.MaMon = c.MaMon
	 WHERE c.MaPhieu = @MaPhieu
			)


	DECLARE @Loai NVARCHAR(20)
	SET @Loai = 
	(SELECT LoaiThe
	FROM TheKhachHang 
	WHERE TrangThaiThe = 1 AND MaKhachHang = 
	(SELECT MaKhachHang
	FROM PhieuDatMon p
	WHERE p.MaPhieu = @MaPhieu
	)
	)
	IF @Loai IS NULL
	BEGIN
		 RAISERROR (N'Không tìm thấy loại thẻ hợp lệ cho khách hàng này', 16, 1);
    RETURN;
	END;
	IF(@Loai = N'Membership')
	BEGIN
		SET @GiamGia = 0;
	END;
	ELSE IF(@Loai = N'Silver')
	BEGIN
		SET @GiamGia = 5;
	END;
	ELSE IF(@Loai = N'Gold')
	BEGIN
		SET @GiamGia = 10;
	END;

	SET @ThanhTien = @TongTien * (100 - @GiamGia) / 100.0;

	INSERT INTO HoaDon (MaPhieu, NgayLap, TongTien, GiamGia,ThanhTien)
	VALUES (@MaPhieu, Getdate(),@TongTien, @GiamGia, @ThanhTien)

END;
GO
	

CREATE PROC INHOADON
    @MaPhieu BIGINT
AS
BEGIN
    -- Kiểm tra mã phiếu
    IF NOT EXISTS (SELECT 1 FROM HoaDon WHERE MaPhieu = @MaPhieu)
    BEGIN
        RAISERROR (N'Hóa đơn không tồn tại cho mã phiếu đã nhập', 16, 1);
        RETURN;
    END;

    -- Thông tin hóa đơn
    PRINT N'========== THÔNG TIN HÓA ĐƠN =========='
    SELECT 
        h.MaPhieu AS [Số hóa đơn],
        h.NgayLap AS [Ngày lập hóa đơn],
        p.MaKhachHang AS [Mã khách hàng],
        k.HoTen AS [Tên khách hàng]
    FROM HoaDon h
    INNER JOIN PhieuDatMon p ON h.MaPhieu = p.MaPhieu
    LEFT JOIN KhachHang k ON p.MaKhachHang = k.MaKhachHang
    WHERE h.MaPhieu = @MaPhieu;

    PRINT N'---------- DANH SÁCH MÓN ĂN -----------'
    -- Chi tiết phiếu
    SELECT 
        m.TenMon AS [Tên món ăn],
        c.SoLuong AS [Số lượng],
        m.GiaHienTai AS [Đơn giá (VND)],
        (m.GiaHienTai * c.SoLuong) AS [Thành tiền (VND)]
    FROM ChiTietPhieu c
    INNER JOIN Mon m ON c.MaMon = m.MaMon
    WHERE c.MaPhieu = @MaPhieu;

	PRINT N'========== THÔNG TIN THANH TOÁN =========='
    SELECT 
        h.TongTien AS [Tổng tiền (VND)],
        h.GiamGia AS [Giảm giá (%)],
        h.ThanhTien AS [Thành tiền (VND)]
    FROM HoaDon h
    INNER JOIN PhieuDatMon p ON h.MaPhieu = p.MaPhieu
    WHERE h.MaPhieu = @MaPhieu;

    PRINT N'========================================'
    PRINT N'Cảm ơn quý khách đã sử dụng dịch vụ. Hẹn gặp lại!'
END;
GO

--SP XEM THÔNG TIN NHÂN VIÊN CHÍNH MÌNH -- LIÊN QUAN ĐẾN PHÂN QUYỀN




---------STORE PROCEDURE PHÂN HỆ CHI NHÁNH
--SP TÌM KIẾM THÔNG TIN NHÂN VIÊN BẰNG MÃ NHÂN VIÊN/ TÊN NHÂN VIÊN/...
CREATE PROC TIMTTNV
    @MaNhanVien CHAR(6)
AS
BEGIN
    -- Kiểm tra mã nhân viên
    IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE MaNhanVien = @MaNhanVien)
    BEGIN
        RAISERROR (N'Mã nhân viên nhập vào không có trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

    -- In thông tin nhân viên
    PRINT N'========== THÔNG TIN NHÂN VIÊN =========='
    SELECT 
        MaNhanVien AS [Mã nhân viên], 
        HoTen AS [Họ và tên], 
        FORMAT(NgaySinh, 'dd/MM/yyyy') AS [Ngày sinh], 
        CASE GioiTinh WHEN 'M' THEN N'Nam' ELSE N'Nữ' END AS [Giới tính],
        FORMAT(NgayVaoLam, 'dd/MM/yyyy') AS [Ngày vào làm], 
        FORMAT(NgayNghiViec, 'dd/MM/yyyy') AS [Ngày nghỉ việc], 
        MaBoPhan AS [Mã bộ phận], 
        DiemSo AS [Điểm số]
    FROM NhanVien
    WHERE MaNhanVien = @MaNhanVien;

    -- In lịch sử làm việc
    PRINT N'========== LỊCH SỬ LÀM VIỆC =========='
    SELECT 
        MaChiNhanh AS [Mã chi nhánh],
        FORMAT(NgayBatDau, 'dd/MM/yyyy') AS [Ngày bắt đầu],
        FORMAT(NgayKetThuc, 'dd/MM/yyyy') AS [Ngày kết thúc]
    FROM LichSuLamViec
    WHERE MaNhanVien = @MaNhanVien
    ORDER BY NgayBatDau DESC;

END;
GO

--EXEC TIMTTNV @MaNhanVien = 'NV001';
--SP XEM DANH SÁCH TẤT CẢ NHÂN VIÊN THUỘC HỆ THỐNG/KHU VỰC/ CHI NHÁNH
CREATE PROC XEMNVHT
AS
BEGIN
    PRINT N'========== DANH SÁCH TẤT CẢ NHÂN VIÊN =========='
    SELECT 
        MaNhanVien AS [Mã nhân viên], 
        HoTen AS [Họ và tên], 
        FORMAT(NgaySinh, 'dd/MM/yyyy') AS [Ngày sinh], 
        CASE GioiTinh WHEN 'M' THEN N'Nam' ELSE N'Nữ' END AS [Giới tính],
        FORMAT(NgayVaoLam, 'dd/MM/yyyy') AS [Ngày vào làm], 
        FORMAT(NgayNghiViec, 'dd/MM/yyyy') AS [Ngày nghỉ việc], 
        MaBoPhan AS [Mã bộ phận], 
        DiemSo AS [Điểm số]
    FROM NhanVien;
END;
GO


CREATE PROC XEMNVKHUVUC
    @MaKhuVuc TINYINT
AS
BEGIN
    -- Kiểm tra mã khu vực
    IF NOT EXISTS (SELECT 1 FROM KhuVuc WHERE MaKhuVuc = @MaKhuVuc)
    BEGIN
        RAISERROR (N'Mã khu vực nhập vào không tồn tại trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

    PRINT N'========== DANH SÁCH NHÂN VIÊN KHU VỰC =========='
    SELECT 
        n.MaNhanVien AS [Mã nhân viên], 
        n.HoTen AS [Họ và tên], 
        FORMAT(n.NgaySinh, 'dd/MM/yyyy') AS [Ngày sinh], 
        CASE n.GioiTinh WHEN 'M' THEN N'Nam' ELSE N'Nữ' END AS [Giới tính],
        FORMAT(n.NgayVaoLam, 'dd/MM/yyyy') AS [Ngày vào làm], 
        FORMAT(n.NgayNghiViec, 'dd/MM/yyyy') AS [Ngày nghỉ việc]
    FROM 
        NhanVien n 
    INNER JOIN 
        LichSuLamViec l ON n.MaNhanVien = l.MaNhanVien
    WHERE 
        l.NgayKetThuc IS NULL 
        AND l.MaChiNhanh IN (SELECT MaChiNhanh FROM ChiNhanh WHERE MaKhuVuc = @MaKhuVuc);
END;
GO


CREATE PROC XEMNVCN
    @MaChiNhanh TINYINT
AS
BEGIN
    -- Kiểm tra mã chi nhánh
    IF NOT EXISTS (SELECT 1 FROM ChiNhanh WHERE MaChiNhanh = @MaChiNhanh)
    BEGIN
        RAISERROR (N'Mã chi nhánh nhập vào không tồn tại trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

    PRINT N'========== DANH SÁCH NHÂN VIÊN CHI NHÁNH =========='
    SELECT 
        n.MaNhanVien AS [Mã nhân viên], 
        n.HoTen AS [Họ và tên], 
        FORMAT(n.NgaySinh, 'dd/MM/yyyy') AS [Ngày sinh], 
        CASE n.GioiTinh WHEN 'M' THEN N'Nam' ELSE N'Nữ' END AS [Giới tính],
        FORMAT(n.NgayVaoLam, 'dd/MM/yyyy') AS [Ngày vào làm], 
        FORMAT(n.NgayNghiViec, 'dd/MM/yyyy') AS [Ngày nghỉ việc]
    FROM 
        NhanVien n 
    INNER JOIN 
        LichSuLamViec l ON n.MaNhanVien = l.MaNhanVien
    WHERE 
        l.NgayKetThuc IS NULL 
        AND l.MaChiNhanh = @MaChiNhanh;
END;
GO


--SP THÊM NHÂN VIÊN MỚI VÀO BẢNG NHÂN VIÊN
CREATE PROC THEMNV
	@HoTen NVARCHAR(255),
	@NgaySinh DATE,
	@GioiTinh nvarchar(4),
	@NgayVaoLam DATE,
	@MaBoPhan CHAR(4),
	@MaChiNhanh TINYINT
	
AS
BEGIN
	--Kiểm tra mã chi nhánh có tồn tại không
	--Kiểm tra mã bộ phận có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM ChiNhanh WHERE MaChiNhanh = @MaChiNhanh)
    BEGIN
        RAISERROR (N'Mã chi nhánh nhập vào không có trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;
	--Kiểm tra mã bộ phận có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM BoPhan WHERE MaBoPhan = @MaBoPhan)
    BEGIN
        RAISERROR (N'Mã bộ phận nhập vào không có trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

	DECLARE @MaNhanVien CHAR(6);

    -- Tìm số thứ tự bị thiếu trong dãy mã nhân viên
    SET @MaNhanVien = 
(
    SELECT TOP 1 
           'NV' + RIGHT('0000' + CAST(MissingNumber AS VARCHAR), 4)
    FROM 
    (
        SELECT t.Number + 1 AS MissingNumber
        FROM 
        (
            SELECT CAST(SUBSTRING(MaNhanVien, 3, LEN(MaNhanVien) - 2) AS INT) AS Number
            FROM NhanVien
        ) t
        WHERE NOT EXISTS 
        (
            SELECT 1
            FROM NhanVien n
            WHERE CAST(SUBSTRING(n.MaNhanVien, 3, LEN(n.MaNhanVien) - 2) AS INT) = t.Number + 1
        )
    ) MissingNumbers
    ORDER BY MissingNumber
);

    -- Nếu không tìm thấy số bị thiếu, tạo mã mới dựa trên số lớn nhất
    IF @MaNhanVien IS NULL
    BEGIN
        SET @MaNhanVien = 
        (
            SELECT 'NV' + RIGHT('0000' + CAST(ISNULL(MAX(CAST(SUBSTRING(MaNhanVien, 3, LEN(MaNhanVien) - 2) AS INT)), 0) + 1 AS VARCHAR), 4)
            FROM NhanVien
        );
    END;


    -- Kiểm tra lần cuối nếu @MaNhanVien vẫn NULL
    IF @MaNhanVien IS NULL
    BEGIN
        RAISERROR (N'Không thể tạo mã nhân viên mới. Vui lòng kiểm tra lại dữ liệu.', 16, 1);
        RETURN;
    END;



	INSERT INTO NhanVien (MaNhanVien, HoTen, NgaySinh, 
	GioiTinh, NgayVaoLam, NgayNghiViec,MaBoPhan)
	VALUES (@MaNhanVien, @HoTen, @NgaySinh, @GioiTinh, GETDATE(),NULL, @MaBoPhan);

	INSERT INTO LichSuLamViec(MaNhanVien,MaChiNhanh, NgayBatDau, NgayKetThuc)
	VALUES (@MaNhanVien, @MaChiNhanh, @NgayVaoLam,NULL)

	PRINT N'Thêm nhân viên thành công. Mã nhân viên mới là ' + @MaNhanVien;
END;
GO


--SP CẬP NHẬT THÔNG TIN NHÂN VIÊN: SỬA ĐIỂM, LƯƠNG, THÊM NGÀY NGHỈ VIỆC
CREATE PROCEDURE CAPNHAT_NHANVIEN @MANHANVIEN CHAR(6), @HOTEN NVARCHAR(255), @NGAYSINH DATE,@GIOITINH NVARCHAR(4), @LUONG DECIMAL(18,3), @NGAYVAOLAM DATE, @NGAYNGHIVIEC DATE, @MABOPHAN CHAR(4), @DIEMSO DECIMAL(9,0)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE MaNhanVien = @MANHANVIEN)
		BEGIN
			RAISERROR(N'Nhân viên không tồn tại',16,1)
		END
	ELSE
		BEGIN
			UPDATE NhanVien
				SET 
					HoTen = COALESCE(@HOTEN, HoTen),
					NgaySinh = COALESCE(@NGAYSINH, NgaySinh),
					GioiTinh = COALESCE(@GIOITINH, GioiTinh),
					NgayVaoLam = COALESCE(@NGAYVAOLAM, NgayVaoLam),
					NgayNghiViec = COALESCE(@NGAYNGHIVIEC, NgayNghiViec),
					MaBoPhan = COALESCE(@MABOPHAN, MaBoPhan),
					DiemSo = COALESCE(@DIEMSO, DiemSo)
				WHERE MaNhanVien = @MANHANVIEN;

    PRINT 'Cập nhật thông tin nhân viên thành công.';
		END
END
GO


--SP SỬA THÔNG TIN TRÊN BẢNG LỊCH SỬ LÀM VIỆC KHI NHÂN VIÊN NGHỈ VIỆC 
CREATE PROC NVNGHIVIEC
	@MANHANVIEN CHAR(6)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE MaNhanVien = @MaNhanVien)
    BEGIN
        RAISERROR (N'Mã nhân viên nhập vào không có trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

	UPDATE LichSuLamViec
	SET NgayKetThuc = GETDATE()
	WHERE NgayKetThuc = NULL
	PRINT N'Thêm thông tin thành công';
END;
GO


-- SP ĐIỀU ĐỘNG SANG CHI NHÁNH KHÁC
CREATE PROC DIEUDONGNV
	@MANHANVIEN CHAR(6), @MACHINHANHCU TINYINT, @MACHINHANHMOI TINYINT
AS
BEGIN
	--KIEM TRA MA NHAN VIEN
	IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE MaNhanVien = @MaNhanVien)
    BEGIN
        RAISERROR (N'Mã nhân viên nhập vào không có trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;
	-- Kiểm tra mã chi nhánh
    IF NOT EXISTS (SELECT 1 FROM ChiNhanh WHERE MaChiNhanh = @MACHINHANHCU)
    BEGIN
        RAISERROR (N'Mã chi nhánh cũ nhập vào không tồn tại trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;
	-- Kiểm tra mã chi nhánh
    IF NOT EXISTS (SELECT 1 FROM ChiNhanh WHERE MaChiNhanh = @MACHINHANHMOI)
    BEGIN
        RAISERROR (N'Mã chi nhánh mới nhập vào không tồn tại trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

	UPDATE LichSuLamViec
	SET NgayKetThuc = GETDATE()
	WHERE NgayKetThuc = NULL AND MaChiNhanh = @MACHINHANHCU

	INSERT INTO LichSuLamViec (MaNhanVien, MaChiNhanh, NgayBatDau,NgayKetThuc)
	VALUES (@MANHANVIEN, @MACHINHANHMOI, GETDATE(),NULL)

	PRINT N'Thực hiện đổi chi nhánh thành công';
END;
GO



--SP CHỈNH SỬA TRẠNG THÁI PHỤC VỤ CỦA MÓN ĂN TRONG THỰC ĐƠN
CREATE PROC TRANGTHAIMONAN
	@MACHINHANH TINYINT, @MAMON TINYINT
AS
BEGIN
	-- Kiểm tra mã chi nhánh
    IF NOT EXISTS (SELECT 1 FROM ChiNhanh WHERE MaChiNhanh = @MACHINHANH)
    BEGIN
        RAISERROR (N'Mã chi nhánh cũ nhập vào không tồn tại trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;
	-- Kiểm tra mã món
    IF NOT EXISTS (SELECT 1 FROM Mon WHERE MaMon = @MAMON)
    BEGIN
        RAISERROR (N'Mã món nhập vào không tồn tại trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;
	-- Kiểm tra mã món TRONG PHUC VU
    IF NOT EXISTS (SELECT 1 FROM PhucVu WHERE MaMon = @MAMON AND MaChiNhanh= @MACHINHANH)
    BEGIN
        RAISERROR (N'Chi nhánh này hiện chưa phục vụ món ăn bạn đang tìm. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

	UPDATE PhucVu
	SET CoPhucVuKhong = 0
	WHERE MaMon = @MAMON

	PRINT N'Sửa thông tin món ăn thành công';
END;
GO

--SP XÓA PHIEU DAT MON
CREATE PROC XOAPDM
	@MAPHIEU BIGINT
AS
BEGIN
	IF NOT EXISTS (SELECT 1
	FROM PhieuDatMon
	WHERE MaPhieu = @MAPHIEU
	)
	BEGIN
		RAISERROR (N'Mã phiếu đặt món nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;

	DELETE FROM PhieuDatMon
	WHERE MaPhieu = @MAPHIEU
	PRINT N'Xóa phiếu đặt món thành công';
END;
GO

--XÓA THÔNG TIN MÓN TRÊN PHIẾU ĐẶT MÓN.
CREATE PROC XOATTPDM
	@MAPHIEU BIGINT , @MAMON TINYINT
AS
BEGIN
	--Kiểm tra mã phiếu 
	IF NOT EXISTS (SELECT 1
	FROM PhieuDatMon
	WHERE MaPhieu = @MAPHIEU
	)
	BEGIN
		RAISERROR (N'Mã phiếu đặt món nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;
	--Kiểm tra mã món
	IF NOT EXISTS (SELECT 1 FROM Mon WHERE MaMon = @MAMON)
    BEGIN
        RAISERROR (N'Mã món nhập vào không tồn tại trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;
	--Kiểm tra món có nằm trong phiếu đó không
	IF NOT EXISTS 
	(SELECT 1
	FROM ChiTietPhieu
	WHERE MaPhieu = @MAPHIEU AND MaMon = @MAMON)
	BEGIN
        RAISERROR (N'Món ăn này không có trong phiếu đặt món trên. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

	DELETE FROM ChiTietPhieu
	WHERE MaMon = @MAMON AND MaPhieu = @MAPHIEU
	PRINT N'Xóa món thành công';
END;
GO


--SP THÊM THÔNG TIN THẺ KHÁCH HÀNG 
CREATE PROC THEMTHEKH
	@MAKHACHHANG BIGINT, @NHANVIENLAP CHAR(6) 
AS
BEGIN
	--Kiểm tra mã khách hàng có tồn tại không
	IF NOT EXISTS (SELECT 1
	FROM KhachHang
	WHERE MaKhachHang = @MAKHACHHANG
	)
	BEGIN
		RAISERROR (N'Mã khách hàng nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;
	--Kiểm tra khách hàng đã có thẻ trước đó hay không
	IF EXISTS (SELECT 1
	FROM TheKhachHang
	WHERE MaKhachHang = @MAKHACHHANG
	)
	BEGIN
		RAISERROR (N'Khách hàng đã có thẻ khách hàng trước đó',16,1);
		RETURN;
	END;
	--KIỂM TRA NHÂN VIÊN
	IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE MaNhanVien = @NHANVIENLAP)
    BEGIN
        RAISERROR (N'Mã nhân viên nhập vào không có trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

	DECLARE @MASOTHE INT
	SET @MASOTHE = (SELECT ISNULL(MAX(MaSoThe), 0) + 1 FROM TheKhachHang);
	--note
	INSERT INTO TheKhachHang(MaSoThe, MaKhachHang, NhanVienLap)
	VALUES (@MASOTHE, @MAKHACHHANG, @NHANVIENLAP)
	PRINT N'Thêm thẻ khách hàng thành công';
END;
GO




--SP CẬP NHẬT THÔNG TIN ĐIỂM KHÁCH HÀNG
--NOTE
CREATE PROCEDURE CAPNHAT_THEKHACHHANG
	@MASOTHE CHAR(12), @MAKHACHHANG BIGINT, @NGAYLAP DATE, @NHANVIENLAP CHAR(6), @TRANGTHAITHE BIT , @DIEMHIENTAI INT, @DIEMTICHLUY INT, @NGAYDATTHE DATE, @LOAITHE NVARCHAR(20)
AS
BEGIN
	--Kiểm tra mã số thẻ khách hàng có tồn tại không
	IF NOT EXISTS (SELECT 1
	FROM TheKhachHang
	WHERE MaSoThe = @MASOTHE
	)
	BEGIN
		RAISERROR (N'Mã số thẻ khách hàng nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;
	--Kiểm tra mã khách hàng có tồn tại không
	IF NOT EXISTS (SELECT 1
	FROM KhachHang
	WHERE MaKhachHang = @MAKHACHHANG
	)
	BEGIN
		RAISERROR (N'Mã khách hàng nhập vào không có trong hệ thống',16,1);
		RETURN;
	END;
	--KIỂM TRA NHÂN VIÊN
	IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE MaNhanVien = @NHANVIENLAP)
    BEGIN
        RAISERROR (N'Mã nhân viên nhập vào không có trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

	UPDATE TheKhachHang
	SET 
					MaKhachHang = COALESCE(@MAKHACHHANG, MaKhachHang),
					NgayLap = COALESCE(@NGAYLAP, NgayLap),
					NhanVienLap = COALESCE(@NHANVIENLAP,NhanVienLap),
					TrangThaiThe = COALESCE(@TRANGTHAITHE, TrangThaiThe),
					DiemHienTai = COALESCE(@DIEMHIENTAI, DiemHienTai),
					DiemTichLuy = COALESCE(@DIEMTICHLUY, DiemTichLuy),
					--NgayDatThe = COALESCE(@MABOPHAN, MaBoPhan),
					LoaiThe = COALESCE(@LOAITHE, LoaiThe)
				WHERE MaSoThe = @MASOTHE;

    PRINT 'Cập nhật thông tin thẻ khách hàng thành công.';
END
GO


--SP XÓA THẺ KHÁCH HÀNG KHI KHÁCH HÀNG BÁO MẤT THẺ
CREATE PROC XOATHEKH
	@SOCCCD CHAR(12), @HOTEN NVARCHAR(255), @SODIENTHOAI CHAR(10)
AS
BEGIN
	--KIỂM TRA SCCCD
	IF NOT EXISTS (SELECT 1 FROM KhachHang WHERE SoCCCD = @SOCCCD)
    BEGIN
        RAISERROR (N'Số CCCD này không có trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;
	--KIỂM TRA KHÁCH HÀNG CÓ THẺ KHÁCH HÀNG KHÔNG
	IF NOT EXISTS (SELECT 1 FROM TheKhachHang WHERE MaKhachHang = 
	(SELECT MaKhachHang FROM KhachHang WHERE SoCCCD = @SOCCCD))
    BEGIN
        RAISERROR (N'Khách hàng này không có thẻ khách hàng trong hệ thống. Vui lòng kiểm tra lại.', 16, 1);
        RETURN;
    END;

	DELETE FROM TheKhachHang
	WHERE MaKhachHang = (SELECT MaKhachHang FROM KhachHang WHERE SoCCCD = @SOCCCD)
	PRINT N'Xóa thẻ khách hàng thành công';
END;
GO






--STORED PROCEDURE PH KHACH HANG
-- Stored procedure phân hệ KHÁCH HÀNG

--1. ĐĂNG KÍ TÀI KHOẢN
CREATE PROCEDURE SP_DANGKI_TAIKHOAN
	@HoTen NVARCHAR(255), @SoDienThoai CHAR(10),
	@Email VARCHAR (255), @SoCCCD CHAR (12),
	@GioiTinh NVARCHAR(4)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM KhachHang WHERE SoCCCD = @SoCCCD 
		OR SoDienThoai = @SoDienThoai OR Email = @Email)
		BEGIN
			RAISERROR(N'Thông tin khách hàng đã tồn tại',16,1);
			RETURN;
		END;

		INSERT INTO KhachHang (SoCCCD, SoDienThoai, Email, HoTen, GioiTinh)
		VALUES (@SoCCCD, @SoDienThoai, @Email, @HoTen, @GioiTinh)
END;

--2. ĐĂNG NHẬP
/*
CREATE PROCEDURE SP_DANGNHAP
    @Email NVARCHAR(50),
    @MatKhau VARCHAR(100)
AS
BEGIN
    SELECT * 
    FROM KhachHang
    WHERE Email = @Email AND MatKhau = @MatKhau;
END;

*/

--3. QUẢN LÝ THÔNG TIN CÁ NHÂN
----NOTE THÊM CHỈNH SỬA SOCCCD
CREATE PROCEDURE SP_CAPNHAT_THONGTINCANHAN
	@MaKhachHang BIGINT, @SoDienThoai CHAR(10),@Email VARCHAR(255), @GioiTinh NVARCHAR(4)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM KhachHang WHERE (SoDienThoai = @SoDienThoai OR Email = @Email)
			AND MaKhachHang != @MaKhachHang)
	BEGIN 
		RAISERROR('Thông tin vừa cập nhật giống với thông tin đã tồn tại',16,1);
		RETURN;
	END;

	UPDATE KhachHang
	SET SoDienThoai = COALESCE(@SoDienThoai, SoDienThoai),
		Email = COALESCE(@Email, Email),
		GioiTinh = COALESCE (@GioiTinh, GioiTinh)
	WHERE MaKhachHang = @MaKhachHang;
END;
--4. ĐẶT BÀN TRỰC TUYẾN -- khi khách hàng đến, nhân viên sẽ kiểm tra các phiếu đặt món của khách hàng mà chưa có hóa đơn
-- Bổ sung thêm như quy trình trên mess đã miêu tả
CREATE PROCEDURE SP_DATBAN_TRUCTUYEN
	@MaKhachHang BIGINT, @MaChiNhanh TINYINT, @SoLuongKhach TINYINT,
	@GioDen DATETIME, @GhiChu NVARCHAR(255)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM KhachHang WHERE MaKhachHang = @MaKhachHang)
	BEGIN
		RAISERROR(N'Không tìm thấy mã khách hàng!', 16,1);
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM ChiNhanh WHERE MaChiNhanh = @MaChiNhanh)
	BEGIN
		RAISERROR(N'Không tìm thấy mã chi nhánh', 16,1);
		RETURN;
	END;

	INSERT INTO DatTruoc (MaKhachHang, MaChiNhanh, SoLuongKhach, GioDen, GhiChu)
	VALUES (@MaKhachHang, @MaChiNhanh, @SoLuongKhach, @GioDen, @GhiChu);
END;
--5. ĐẶT MÓN TRỰC TUYẾN
--Phải tạo trước phiếu đặt món trước rồi mới thêm món được, không có nhập vào mã phiếu được
CREATE PROCEDURE SP_DATMON_TRUCTUYEN
	@MaPhieu BIGINT, @MaMon SMALLINT, @SoLuong TINYINT, @GhiChu NVARCHAR(200)
AS 
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM Mon M
		JOIN PhucVu P ON M.MaMon = P.MaMon
		WHERE M.MaMon = @MaMon AND P.CoPhucVuKhong = 0 )
	BEGIN 
		RAISERROR(N'Món ăn không tồn tại hoặc không được phục vụ', 16, 1);
		RETURN;
	END;
	
	INSERT INTO ChiTietPhieu (MaPhieu, MaMon, SoLuong, GhiChu)
	VALUES (@MaPhieu, @MaMon, @SoLuong, @GhiChu);
END;
--6. THANH TOÁN TRỰC TUYỂN

CREATE PROCEDURE SP_THANHTOAN_TRUCTUYEN
    @MaPhieu BIGINT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM HoaDon WHERE MaPhieu = @MaPhieu)
    BEGIN
        RAISERROR(N'Phiếu đặt món đã được thanh toán!', 16, 1);
        RETURN;
    END;

    DECLARE @TongTien DECIMAL(10, 2);
    SELECT @TongTien = SUM(CTP.SoLuong * M.GiaHienTai)
    FROM ChiTietPhieu CTP
    JOIN Mon M ON CTP.MaMon = M.MaMon
    WHERE CTP.MaPhieu = @MaPhieu;

    IF @TongTien IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy chi tiết phiếu đặt món!', 16, 1);
        RETURN;
    END;

    DECLARE @MaKhachHang INT;
    SELECT @MaKhachHang = PD.MaKhachHang
    FROM PhieuDatMon PD
    WHERE PD.MaPhieu = @MaPhieu;

    IF @MaKhachHang IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy khách hàng liên quan đến phiếu đặt món!', 16, 1);
        RETURN;
    END;

    DECLARE @LoaiThe NVARCHAR(20) = N'Membership';
    DECLARE @GiamGia DECIMAL(5, 2) = 0;

    SELECT @LoaiThe = TK.LoaiThe
    FROM TheKhachHang TK
    WHERE TK.MaKhachHang = @MaKhachHang;

    SET @GiamGia = CASE 
                      WHEN @LoaiThe = N'Gold' THEN @TongTien * 0.1
                      WHEN @LoaiThe = N'Silver' THEN @TongTien * 0.05
                      ELSE 0
                   END;

    INSERT INTO HoaDon (MaPhieu, NgayLap, TongTien, GiamGia, ThanhTien)
    VALUES (@MaPhieu, GETDATE(), @TongTien, @GiamGia, @TongTien - @GiamGia);

    PRINT N'Thanh toán thành công. Hóa đơn đã được tạo!';
END;


--7. ĐÁNH GIÁ DỊCH VỤ
CREATE PROCEDURE SP_DANHGIA_DICHVU
	@MaPhieu BIGINT, @DiemPhucVu TINYINT,  @DiemViTri TINYINT,
    @DiemChatLuong TINYINT, @DiemKhongGian TINYINT, @BinhLuan NVARCHAR(MAX)
AS 
BEGIN
	IF @DiemPhucVu NOT BETWEEN 1 AND 5
	OR @DiemViTri NOT BETWEEN 1 AND 5
	OR @DiemChatLuong NOT BETWEEN 1 AND 5
	OR @DiemKhongGian NOT BETWEEN 1 AND 5
	BEGIN
		RAISERROR(N'Điểm đánh giá phải từ 1 đến 5!', 16, 1);
		RETURN;
	END;

	INSERT INTO DanhGia(MaPhieu, DiemPhucVu, DiemViTri, DiemChatLuong, DiemKhongGian, BinhLuan)
	VALUES (@MaPhieu, @DiemPhucVu, @DiemViTri, @DiemChatLuong, @DiemKhongGian, @BinhLuan);
END;

--8. THEO DÕI LỊCH SỬ ĐẶT BÀN
CREATE PROCEDURE SP_LICHSU_DATBAN
	@MaKhachHang BIGINT
AS
BEGIN
	SELECT MaDatTruoc, MaChiNhanh, SoLuongKhach, GioDen, GhiChu
	FROM DatTruoc
	WHERE MaKhachHang = @MaKhachHang;
END;
--9. THEO DÕI LỊCH SỬ ĐẶT MÓN

CREATE PROCEDURE SP_LICHSU_DATMON
	@MaKhachHang BIGINT
AS
BEGIN 
	SELECT PD.MaPhieu, CTP.MaMon, CTP.SoLuong
	FROM PhieuDatMon PD
	JOIN ChiTietPhieu CTP ON PD.MaPhieu = CTP.MaPhieu
	WHERE PD.MaKhachHang = @MaKhachHang;
END;


--10. XEM THÔNG TIN THẺ THÀNH VIÊN
CREATE PROCEDURE SP_XEMTHONGTIN_THETHANHVIEN
    @MaKhachHang BIGINT
AS
BEGIN
    SELECT LoaiThe, DiemHienTai, DiemTichLuy
    FROM TheKhachHang
    WHERE MaKhachHang = @MaKhachHang;
END;

--11. GỬI PHẢN HỒI (CÁI NÀY GIỐNG ĐÁNH GIÁ)

--12. HỖ TRỢ GIAO HÀNG (THUỘC VỀ VẬN CHUYỂN)

--13. HỦY ĐƠN HÀNG
CREATE PROCEDURE SP_HUYDONHANG
    @MaPhieu BIGINT
AS
BEGIN
    DELETE FROM PhieuDatMon WHERE MaPhieu = @MaPhieu;
END;

--14. ĐĂNG XUẤT - QUẢN LÝ SESSIONN Ở ỨNG DỤNG

--15. QUÊN MẬT KHẨU
CREATE PROCEDURE SP_QUENMATKHAU
    @Email VARCHAR(255)
AS
BEGIN
    PRINT 'Mã đặt lại mật khẩu đã được gửi qua email.';
END;
-- CẬP NHẬT LOẠI THẺ KHÁCH HÀNG
CREATE PROCEDURE SP_CAPNHAT_LOAITHEKHACHHANG
AS
BEGIN
    -- Cập nhật từ GOLD xuống SILVER
    UPDATE TheKhachHang
    SET LoaiThe = N'Silver',
        NgayDatThe = GETDATE()
    WHERE LoaiThe = N'Gold'
      AND DATEDIFF(DAY, NgayDatThe, GETDATE()) <= 365
      AND DiemTichLuy < 100;

    -- Cập nhật từ SILVER xuống Membership
    UPDATE TheKhachHang
    SET LoaiThe = N'Membership',
        NgayDatThe = GETDATE()
    WHERE LoaiThe = N'Silver'
      AND DATEDIFF(DAY, NgayDatThe, GETDATE()) <= 365
      AND DiemTichLuy < 50;

    -- Nâng từ SILVER lên GOLD
    UPDATE TheKhachHang
    SET LoaiThe = N'Gold',
        NgayDatThe = GETDATE()
    WHERE LoaiThe = N'Silver'
      AND DATEDIFF(DAY, NgayDatThe, GETDATE()) <= 365
      AND DiemTichLuy >= 100;

    -- Cập nhật hạng SILVER
    UPDATE TheKhachHang
    SET LoaiThe = N'Silver',
        NgayDatThe = GETDATE()
    WHERE LoaiThe = N'Membership'
      AND DiemTichLuy >= 100;

    UPDATE TheKhachHang
    SET LoaiThe = N'Membership',
        NgayDatThe = GETDATE()
    WHERE LoaiThe NOT IN (N'Membership', N'Silver', N'Gold');
END;
