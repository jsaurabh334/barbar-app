import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_barbers_bloc.dart';
import 'package:barbar_app/presentation/screens/admin/active_barbers_screen.dart';
import 'package:barbar_app/presentation/screens/admin/pending_barbers_screen.dart';

class AdminBarbersScreen extends StatelessWidget {
  const AdminBarbersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: TabBar(
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(text: 'Active Barbers'),
                  Tab(text: 'Pending Approvals'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  BlocProvider(
                    create: (context) => AdminBarbersBloc(
                      adminRepository: context.read<AdminRepository>(),
                    )..add(LoadActiveBarbers()),
                    child: const ActiveBarbersScreen(showAppBar: false),
                  ),
                  BlocProvider(
                    create: (context) => AdminBarbersBloc(
                      adminRepository: context.read<AdminRepository>(),
                    )..add(LoadPendingBarbers()),
                    child: const PendingBarbersScreen(showAppBar: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
