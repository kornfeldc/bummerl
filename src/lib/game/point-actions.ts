export type PointAction = {
	title: string;
	points: number;
	availablePlayerCounts: number[];
};

export type PointActionGroup = {
	key: 'low' | 'medium' | 'high';
	actions: PointAction[];
};

export const pointActionGroups: PointActionGroup[] = [
	{
		key: 'low',
		actions: [
			{ title: '1er', points: -1, availablePlayerCounts: [2, 3, 4] },
			{ title: '2er', points: -2, availablePlayerCounts: [2, 3, 4] },
			{ title: '3er', points: -3, availablePlayerCounts: [2, 3, 4] },
			{ title: 'Bettler', points: -4, availablePlayerCounts: [3, 4] },
			{ title: 'Ass-Bettler', points: -5, availablePlayerCounts: [3, 4] }
		]
	},
	{
		key: 'medium',
		actions: [
			{ title: 'Schnapser', points: -6, availablePlayerCounts: [3, 4] },
			{ title: 'Gang', points: -9, availablePlayerCounts: [3, 4] },
			{ title: 'Zehnerloch', points: -10, availablePlayerCounts: [3, 4] },
			{ title: 'Bauernschnapser', points: -12, availablePlayerCounts: [3, 4] },
			{ title: 'Kontraschnapser', points: -12, availablePlayerCounts: [3, 4] }
		]
	},
	{
		key: 'high',
		actions: [
			{ title: 'Farbenringerl', points: -18, availablePlayerCounts: [3, 4] },
			{ title: 'Kontrabauernschnapser', points: -24, availablePlayerCounts: [3, 4] },
			{ title: 'Herrenbauernschnapser', points: -24, availablePlayerCounts: [3, 4] }
		]
	}
];

export const pointActions = pointActionGroups.flatMap((group) => group.actions);
